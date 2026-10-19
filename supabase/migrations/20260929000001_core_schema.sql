-- =============================================================================
-- Shakti core schema
-- Tables: profiles, emergency_contacts, incident_reports, live_breadcrumbs,
--         safe_zones, guardian_invites, push_tokens, rate_limits
-- RLS is enabled on every table. Written to be re-runnable where reasonable.
-- =============================================================================

create extension if not exists pgcrypto with schema extensions;

-- -----------------------------------------------------------------------------
-- Shared helpers
-- -----------------------------------------------------------------------------

create or replace function public.touch_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

-- Human label for a trigger_source wire value (mirrors TriggerSource.label in the app).
create or replace function public.trigger_label(p_source text)
returns text
language sql
immutable
set search_path = ''
as $$
  select case p_source
    when 'HUD_TAP'       then 'SOS button'
    when 'TRIPLE_POWER'  then 'Power button x3'
    when 'VOLUME_TRIPLE' then 'Volume key x3'
    when 'SHAKE'         then 'Shake or fall'
    when 'VOICE_KEYWORD' then 'Voice keyword'
    when 'TIMER_EXPIRED' then 'Escort timer expired'
    when 'DECOY_PIN'     then 'Duress PIN'
    else 'SOS'
  end;
$$;

-- -----------------------------------------------------------------------------
-- profiles
-- -----------------------------------------------------------------------------

create table if not exists public.profiles (
  id           uuid primary key references auth.users (id) on delete cascade,
  display_name text not null default 'Shakti user'
               check (char_length(btrim(display_name)) between 1 and 60),
  phone        text check (phone is null or phone ~ '^\+?[0-9]{10,15}$'),
  avatar_url   text check (avatar_url is null or char_length(avatar_url) <= 2048),
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

drop trigger if exists trg_profiles_touch on public.profiles;
create trigger trg_profiles_touch
  before update on public.profiles
  for each row execute function public.touch_updated_at();

-- Auto-create a profile row whenever an auth user is created.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_name text;
begin
  v_name := left(btrim(coalesce(
    nullif(btrim(new.raw_user_meta_data ->> 'display_name'), ''),
    nullif(btrim(new.raw_user_meta_data ->> 'full_name'), ''),
    'Shakti user'
  )), 60);

  insert into public.profiles (id, display_name)
  values (new.id, v_name)
  on conflict (id) do nothing;

  return new;
end;
$$;

revoke all on function public.handle_new_user() from public, anon, authenticated;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- -----------------------------------------------------------------------------
-- emergency_contacts
-- -----------------------------------------------------------------------------

create table if not exists public.emergency_contacts (
  id               uuid primary key default gen_random_uuid(),
  owner_id         uuid not null default auth.uid() references auth.users (id) on delete cascade,
  name             text not null check (char_length(btrim(name)) between 1 and 80),
  phone            text not null check (phone ~ '^\+?[0-9]{10,15}$'),
  relation         text not null default 'guardian' check (char_length(relation) <= 40),
  priority         smallint not null default 1 check (priority between 1 and 5),
  telegram_chat_id text check (telegram_chat_id is null
                               or telegram_chat_id ~ '^(-?[0-9]{1,20}|@[A-Za-z][A-Za-z0-9_]{4,31})$'),
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  unique (owner_id, phone)
);

create index if not exists idx_contacts_owner on public.emergency_contacts (owner_id);

drop trigger if exists trg_contacts_touch on public.emergency_contacts;
create trigger trg_contacts_touch
  before update on public.emergency_contacts
  for each row execute function public.touch_updated_at();

-- -----------------------------------------------------------------------------
-- guardian_invites (defined before the incident tables: is_guardian_of reads it)
-- -----------------------------------------------------------------------------

create table if not exists public.guardian_invites (
  id                     uuid primary key default gen_random_uuid(),
  owner_id               uuid not null default auth.uid() references auth.users (id) on delete cascade,
  -- 8-char Crockford base32 (no I, L, O, U).
  code                   text not null unique check (code ~ '^[0-9A-HJKMNP-TV-Z]{8}$'),
  guardian_user_id       uuid references auth.users (id) on delete cascade,
  status                 text not null default 'PENDING'
                         check (status in ('PENDING', 'ACCEPTED', 'REVOKED')),
  can_view_live_location boolean not null default true,
  expires_at             timestamptz not null default (now() + interval '7 days'),
  accepted_at            timestamptz,
  revoked_at             timestamptz,
  created_at             timestamptz not null default now(),
  updated_at             timestamptz not null default now(),
  check (guardian_user_id is null or guardian_user_id <> owner_id),
  check (status <> 'ACCEPTED' or guardian_user_id is not null)
);

create index if not exists idx_invites_owner on public.guardian_invites (owner_id);
create index if not exists idx_invites_guardian
  on public.guardian_invites (guardian_user_id, owner_id)
  where status = 'ACCEPTED' and revoked_at is null;
-- One live guardianship per (owner, guardian) pair.
create unique index if not exists uq_invites_active_pair
  on public.guardian_invites (owner_id, guardian_user_id)
  where status = 'ACCEPTED' and revoked_at is null;

drop trigger if exists trg_invites_touch on public.guardian_invites;
create trigger trg_invites_touch
  before update on public.guardian_invites
  for each row execute function public.touch_updated_at();

-- True when auth.uid() is an accepted, non-revoked guardian of `owner` with
-- live-location access. SECURITY DEFINER so policies on other tables can call
-- it without granting guardians direct read access to every invite row.
create or replace function public.is_guardian_of(owner uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.guardian_invites g
    where g.owner_id = $1
      and g.guardian_user_id = auth.uid()
      and g.status = 'ACCEPTED'
      and g.revoked_at is null
      and g.can_view_live_location
  );
$$;

revoke all on function public.is_guardian_of(uuid) from public, anon;
grant execute on function public.is_guardian_of(uuid) to authenticated, service_role;

-- -----------------------------------------------------------------------------
-- incident_reports
-- Row shape written by the app: Incident.toRemoteJson()
--   id, trigger_source, status, latitude, longitude, street_address,
--   battery_level, carrier_sms_dispatched, share_token, covert, resolved_at, created_at
-- -----------------------------------------------------------------------------

create table if not exists public.incident_reports (
  id                      uuid primary key default gen_random_uuid(), -- normally client-generated
  user_id                 uuid not null default auth.uid() references auth.users (id) on delete cascade,
  trigger_source          text not null
                          check (trigger_source in ('HUD_TAP', 'TRIPLE_POWER', 'VOLUME_TRIPLE', 'SHAKE',
                                                    'VOICE_KEYWORD', 'TIMER_EXPIRED', 'DECOY_PIN')),
  status                  text not null default 'ACTIVE'
                          check (status in ('COUNTDOWN', 'ACTIVE', 'RESOLVED', 'FALSE_ALARM')),
  latitude                double precision check (latitude between -90 and 90),
  longitude               double precision check (longitude between -180 and 180),
  street_address          text check (street_address is null or char_length(street_address) <= 300),
  battery_level           smallint check (battery_level between 0 and 100),
  share_token             text not null unique
                          check (char_length(share_token) between 22 and 64
                                 and share_token ~ '^[A-Za-z0-9_-]+$'),
  covert                  boolean not null default false,
  telegram_broadcast_sent boolean not null default false,
  carrier_sms_dispatched  boolean not null default false,
  resolved_at             timestamptz,
  created_at              timestamptz not null default now(),
  updated_at              timestamptz not null default now(),
  check ((latitude is null) = (longitude is null))
);

create index if not exists idx_incidents_user_created
  on public.incident_reports (user_id, created_at desc);
-- share_token already has a unique btree index from the UNIQUE constraint; this
-- named index is kept explicit for clarity and survives constraint renames.
create unique index if not exists idx_incidents_share_token
  on public.incident_reports (share_token);

-- Keeps identity columns immutable, stamps updated_at / resolved_at, and stops
-- clients from forging the server-side delivery flag.
create or replace function public.incident_before_update()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.id          := old.id;
  new.user_id     := old.user_id;
  new.share_token := old.share_token;
  new.created_at  := old.created_at;

  if current_user in ('anon', 'authenticated') then
    new.telegram_broadcast_sent := old.telegram_broadcast_sent;
  end if;

  if new.status in ('RESOLVED', 'FALSE_ALARM') and new.resolved_at is null then
    new.resolved_at := now();
  end if;

  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists trg_incidents_before_update on public.incident_reports;
create trigger trg_incidents_before_update
  before update on public.incident_reports
  for each row execute function public.incident_before_update();

create or replace function public.incident_before_insert()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if current_user in ('anon', 'authenticated') then
    new.telegram_broadcast_sent := false;
  end if;
  if new.status in ('RESOLVED', 'FALSE_ALARM') and new.resolved_at is null then
    new.resolved_at := now();
  end if;
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists trg_incidents_before_insert on public.incident_reports;
create trigger trg_incidents_before_insert
  before insert on public.incident_reports
  for each row execute function public.incident_before_insert();

-- -----------------------------------------------------------------------------
-- live_breadcrumbs
-- Row shape written by the app: Breadcrumb.toRemoteJson()
--   incident_id, latitude, longitude, speed_kmh, accuracy_meters,
--   battery_percentage, recorded_at
-- -----------------------------------------------------------------------------

create table if not exists public.live_breadcrumbs (
  id                 bigint generated always as identity primary key,
  incident_id        uuid not null references public.incident_reports (id) on delete cascade,
  -- Denormalised owner so SELECT policies and Realtime checks stay index-only.
  user_id            uuid not null default auth.uid() references auth.users (id) on delete cascade,
  latitude           double precision not null check (latitude between -90 and 90),
  longitude          double precision not null check (longitude between -180 and 180),
  speed_kmh          real check (speed_kmh is null or speed_kmh between 0 and 1000),
  accuracy_meters    real check (accuracy_meters is null or accuracy_meters >= 0),
  battery_percentage smallint check (battery_percentage between 0 and 100),
  recorded_at        timestamptz not null default now(),
  created_at         timestamptz not null default now(),
  -- Lets the offline sync queue retry safely (upsert with ignoreDuplicates).
  unique (incident_id, recorded_at)
);

create index if not exists idx_breadcrumbs_incident_recorded
  on public.live_breadcrumbs (incident_id, recorded_at desc);
create index if not exists idx_breadcrumbs_user
  on public.live_breadcrumbs (user_id);

-- Breadcrumbs are append-only for clients.
create or replace function public.breadcrumb_before_insert()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  -- Never trust a client-supplied owner: derive it from the incident.
  select i.user_id into new.user_id
  from public.incident_reports i
  where i.id = new.incident_id;
  return new;
end;
$$;

drop trigger if exists trg_breadcrumbs_before_insert on public.live_breadcrumbs;
create trigger trg_breadcrumbs_before_insert
  before insert on public.live_breadcrumbs
  for each row execute function public.breadcrumb_before_insert();

-- -----------------------------------------------------------------------------
-- safe_zones (community-contributed; `verified` is set by moderators only)
-- -----------------------------------------------------------------------------

create table if not exists public.safe_zones (
  id          uuid primary key default gen_random_uuid(),
  name        text not null check (char_length(btrim(name)) between 1 and 120),
  description text check (description is null or char_length(description) <= 1000),
  latitude    double precision not null check (latitude between -90 and 90),
  longitude   double precision not null check (longitude between -180 and 180),
  radius_m    integer not null default 200 check (radius_m between 10 and 5000),
  category    text not null default 'other'
              check (category in ('police', 'hospital', 'metro', 'hostel', 'safe_shop', 'other')),
  created_by  uuid default auth.uid() references auth.users (id) on delete set null,
  verified    boolean not null default false,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create index if not exists idx_safe_zones_geo on public.safe_zones (latitude, longitude);

drop trigger if exists trg_safe_zones_touch on public.safe_zones;
create trigger trg_safe_zones_touch
  before update on public.safe_zones
  for each row execute function public.touch_updated_at();

-- -----------------------------------------------------------------------------
-- push_tokens (owner-only)
-- -----------------------------------------------------------------------------

create table if not exists public.push_tokens (
  user_id    uuid not null default auth.uid() references auth.users (id) on delete cascade,
  token      text not null check (char_length(token) between 16 and 4096),
  platform   text not null default 'android' check (platform in ('android', 'ios', 'web')),
  updated_at timestamptz not null default now(),
  primary key (user_id, token)
);

drop trigger if exists trg_push_tokens_touch on public.push_tokens;
create trigger trg_push_tokens_touch
  before update on public.push_tokens
  for each row execute function public.touch_updated_at();

-- -----------------------------------------------------------------------------
-- rate_limits (service role only: RLS on, no policies, no grants)
-- -----------------------------------------------------------------------------

create table if not exists public.rate_limits (
  user_id      uuid not null references auth.users (id) on delete cascade,
  bucket       text not null check (char_length(bucket) between 1 and 64),
  window_start timestamptz not null default now(),
  count        integer not null default 0,
  primary key (user_id, bucket)
);

-- Atomic fixed-window counter. Returns the count *after* this hit.
create or replace function public.bump_rate_limit(p_user_id uuid, p_bucket text, p_window_sec integer)
returns integer
language sql
volatile
security definer
set search_path = ''
as $$
  insert into public.rate_limits as r (user_id, bucket, window_start, count)
  values (p_user_id, p_bucket, now(), 1)
  on conflict (user_id, bucket) do update
    set window_start = case
          when r.window_start <= now() - make_interval(secs => greatest(p_window_sec, 1))
          then now() else r.window_start end,
        count = case
          when r.window_start <= now() - make_interval(secs => greatest(p_window_sec, 1))
          then 1 else r.count + 1 end
  returning r.count;
$$;

revoke all on function public.bump_rate_limit(uuid, text, integer) from public, anon, authenticated;
grant execute on function public.bump_rate_limit(uuid, text, integer) to service_role;

-- -----------------------------------------------------------------------------
-- Row level security
-- -----------------------------------------------------------------------------

alter table public.profiles           enable row level security;
alter table public.emergency_contacts enable row level security;
alter table public.guardian_invites   enable row level security;
alter table public.incident_reports   enable row level security;
alter table public.live_breadcrumbs   enable row level security;
alter table public.safe_zones         enable row level security;
alter table public.push_tokens        enable row level security;
alter table public.rate_limits        enable row level security;

-- Defence in depth: the anon key gets no table privileges at all; it only
-- reaches data through track_incident(). rate_limits is service-role only.
revoke all on public.profiles, public.emergency_contacts, public.guardian_invites,
              public.incident_reports, public.live_breadcrumbs, public.safe_zones,
              public.push_tokens, public.rate_limits
  from anon;
revoke all on public.rate_limits from authenticated;
revoke all on sequence public.live_breadcrumbs_id_seq from anon;

-- profiles --------------------------------------------------------------------
drop policy if exists profiles_select on public.profiles;
create policy profiles_select on public.profiles
  for select to authenticated
  using (
    id = (select auth.uid())
    or public.is_guardian_of(id)
    -- Owners can see the names of their accepted guardians.
    or exists (
      select 1 from public.guardian_invites g
      where g.owner_id = (select auth.uid())
        and g.guardian_user_id = profiles.id
        and g.status = 'ACCEPTED'
        and g.revoked_at is null
    )
  );

drop policy if exists profiles_insert on public.profiles;
create policy profiles_insert on public.profiles
  for insert to authenticated
  with check (id = (select auth.uid()));

drop policy if exists profiles_update on public.profiles;
create policy profiles_update on public.profiles
  for update to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

-- emergency_contacts ------------------------------------------------------------
drop policy if exists contacts_owner_all on public.emergency_contacts;
create policy contacts_owner_all on public.emergency_contacts
  for all to authenticated
  using (owner_id = (select auth.uid()))
  with check (owner_id = (select auth.uid()));

-- guardian_invites --------------------------------------------------------------
-- Creation, acceptance and revocation go through the guardian-invite function
-- (service role). Clients may read their own invites and delete ones they own.
drop policy if exists invites_select on public.guardian_invites;
create policy invites_select on public.guardian_invites
  for select to authenticated
  using (owner_id = (select auth.uid()) or guardian_user_id = (select auth.uid()));

drop policy if exists invites_owner_delete on public.guardian_invites;
create policy invites_owner_delete on public.guardian_invites
  for delete to authenticated
  using (owner_id = (select auth.uid()));

revoke insert, update on public.guardian_invites from authenticated;

-- incident_reports --------------------------------------------------------------
drop policy if exists incidents_select on public.incident_reports;
create policy incidents_select on public.incident_reports
  for select to authenticated
  using (user_id = (select auth.uid()) or public.is_guardian_of(user_id));

drop policy if exists incidents_insert on public.incident_reports;
create policy incidents_insert on public.incident_reports
  for insert to authenticated
  with check (user_id = (select auth.uid()));

drop policy if exists incidents_update on public.incident_reports;
create policy incidents_update on public.incident_reports
  for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

drop policy if exists incidents_delete on public.incident_reports;
create policy incidents_delete on public.incident_reports
  for delete to authenticated
  using (user_id = (select auth.uid()));

-- live_breadcrumbs --------------------------------------------------------------
drop policy if exists breadcrumbs_insert on public.live_breadcrumbs;
create policy breadcrumbs_insert on public.live_breadcrumbs
  for insert to authenticated
  with check (
    exists (
      select 1 from public.incident_reports i
      where i.id = live_breadcrumbs.incident_id
        and i.user_id = (select auth.uid())
    )
  );

drop policy if exists breadcrumbs_select on public.live_breadcrumbs;
create policy breadcrumbs_select on public.live_breadcrumbs
  for select to authenticated
  using (user_id = (select auth.uid()) or public.is_guardian_of(user_id));

drop policy if exists breadcrumbs_delete on public.live_breadcrumbs;
create policy breadcrumbs_delete on public.live_breadcrumbs
  for delete to authenticated
  using (user_id = (select auth.uid()));

revoke update on public.live_breadcrumbs from authenticated;

-- safe_zones --------------------------------------------------------------------
drop policy if exists safe_zones_select on public.safe_zones;
create policy safe_zones_select on public.safe_zones
  for select to authenticated
  using (true);

drop policy if exists safe_zones_insert on public.safe_zones;
create policy safe_zones_insert on public.safe_zones
  for insert to authenticated
  with check (created_by = (select auth.uid()) and verified = false);

drop policy if exists safe_zones_update on public.safe_zones;
create policy safe_zones_update on public.safe_zones
  for update to authenticated
  using (created_by = (select auth.uid()))
  with check (created_by = (select auth.uid()) and verified = false);

drop policy if exists safe_zones_delete on public.safe_zones;
create policy safe_zones_delete on public.safe_zones
  for delete to authenticated
  using (created_by = (select auth.uid()) and verified = false);

-- push_tokens -------------------------------------------------------------------
drop policy if exists push_tokens_owner_all on public.push_tokens;
create policy push_tokens_owner_all on public.push_tokens
  for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

-- rate_limits: intentionally no policies.

-- -----------------------------------------------------------------------------
-- Public tracker RPC
-- -----------------------------------------------------------------------------
-- Looks up an incident by its unguessable share token (>= 22 chars, ~130+ bits)
-- with a single exact-match index probe. Malformed, unknown, stale and resolved
-- (> 24 h) tokens all return the same thing: NULL. There is no pattern
-- matching, so the endpoint cannot be used to enumerate incidents.
create or replace function public.track_incident(p_token text)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_inc   public.incident_reports%rowtype;
  v_name  text;
  v_crumbs jsonb;
  v_last_battery smallint;
begin
  if p_token is null
     or char_length(p_token) not between 22 and 64
     or p_token !~ '^[A-Za-z0-9_-]+$' then
    return null;
  end if;

  select * into v_inc
  from public.incident_reports i
  where i.share_token = p_token;

  if not found then
    return null;
  end if;

  -- Resolved more than 24 h ago: the link is dead.
  if v_inc.status in ('RESOLVED', 'FALSE_ALARM')
     and coalesce(v_inc.resolved_at, v_inc.updated_at) < now() - interval '24 hours' then
    return null;
  end if;

  -- Never-resolved incidents stop being public after 7 days.
  if v_inc.created_at < now() - interval '7 days'
     and coalesce(v_inc.resolved_at, v_inc.updated_at) < now() - interval '24 hours' then
    return null;
  end if;

  select nullif(split_part(btrim(p.display_name), ' ', 1), '')
    into v_name
  from public.profiles p
  where p.id = v_inc.user_id;

  select
    coalesce(jsonb_agg(jsonb_build_object(
      'lat', c.latitude,
      'lng', c.longitude,
      'speed_kmh', c.speed_kmh,
      'accuracy_meters', c.accuracy_meters,
      'battery', c.battery_percentage,
      'recorded_at', c.recorded_at
    ) order by c.recorded_at asc), '[]'::jsonb)
  into v_crumbs
  from (
    select b.latitude, b.longitude, b.speed_kmh, b.accuracy_meters, b.battery_percentage, b.recorded_at
    from public.live_breadcrumbs b
    where b.incident_id = v_inc.id
    order by b.recorded_at desc
    limit 200
  ) c;

  select b.battery_percentage into v_last_battery
  from public.live_breadcrumbs b
  where b.incident_id = v_inc.id and b.battery_percentage is not null
  order by b.recorded_at desc
  limit 1;

  return jsonb_build_object(
    'status', v_inc.status,
    'trigger_label', public.trigger_label(v_inc.trigger_source),
    'created_at', v_inc.created_at,
    'updated_at', v_inc.updated_at,
    'resolved_at', v_inc.resolved_at,
    'latitude', v_inc.latitude,
    'longitude', v_inc.longitude,
    'last_address', v_inc.street_address,
    'battery', coalesce(v_last_battery, v_inc.battery_level),
    'first_name', coalesce(v_name, 'Shakti user'),
    'breadcrumbs', v_crumbs
  );
end;
$$;

revoke all on function public.track_incident(text) from public;
grant execute on function public.track_incident(text) to anon, authenticated, service_role;

-- -----------------------------------------------------------------------------
-- Realtime
-- -----------------------------------------------------------------------------

do $$
begin
  begin
    alter publication supabase_realtime add table public.live_breadcrumbs;
  exception
    when duplicate_object then null;  -- already a member
    when undefined_object then        -- publication missing (plain Postgres)
      raise notice 'supabase_realtime publication not found; skipping';
  end;
  begin
    alter publication supabase_realtime add table public.incident_reports;
  exception
    when duplicate_object then null;
    when undefined_object then
      raise notice 'supabase_realtime publication not found; skipping';
  end;
end;
$$;

-- -----------------------------------------------------------------------------
-- Storage: private evidence bucket, one folder per user (<uid>/<file>)
-- -----------------------------------------------------------------------------

insert into storage.buckets (id, name, public)
values ('evidence', 'evidence', false)
on conflict (id) do update set public = false;

drop policy if exists evidence_owner_select on storage.objects;
create policy evidence_owner_select on storage.objects
  for select to authenticated
  using (bucket_id = 'evidence' and (storage.foldername(name))[1] = (select auth.uid())::text);

drop policy if exists evidence_owner_insert on storage.objects;
create policy evidence_owner_insert on storage.objects
  for insert to authenticated
  with check (bucket_id = 'evidence' and (storage.foldername(name))[1] = (select auth.uid())::text);

drop policy if exists evidence_owner_update on storage.objects;
create policy evidence_owner_update on storage.objects
  for update to authenticated
  using (bucket_id = 'evidence' and (storage.foldername(name))[1] = (select auth.uid())::text)
  with check (bucket_id = 'evidence' and (storage.foldername(name))[1] = (select auth.uid())::text);

drop policy if exists evidence_owner_delete on storage.objects;
create policy evidence_owner_delete on storage.objects
  for delete to authenticated
  using (bucket_id = 'evidence' and (storage.foldername(name))[1] = (select auth.uid())::text);
