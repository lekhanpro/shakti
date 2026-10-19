-- =============================================================================
-- RLS / RPC assertions for the Shakti core schema.
--
-- Run against a local stack after migrations (needs Docker):
--   supabase start
--   psql "postgresql://postgres:postgres@127.0.0.1:54322/postgres" -v ON_ERROR_STOP=1 -f supabase/tests/rls_test.sql
--
-- Everything runs inside one transaction that is rolled back. Each check
-- raises an exception on failure, so a clean run prints only NOTICEs.
-- =============================================================================

begin;

-- ---------------------------------------------------------------------------
-- Fixtures (as postgres, which bypasses RLS)
--   A = Asha (incident owner), B = Bina (unrelated user), G = Gauri (guardian)
-- ---------------------------------------------------------------------------
insert into auth.users (id, email, raw_user_meta_data)
values
  ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'asha@example.test',  '{"display_name":"Asha Verma"}'),
  ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 'bina@example.test',  '{"display_name":"Bina Rao"}'),
  ('99999999-9999-4999-8999-999999999999', 'gauri@example.test', '{"display_name":"Gauri Iyer"}');

do $$
begin
  if (select count(*) from public.profiles where id in (
        'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
        '99999999-9999-4999-8999-999999999999')) <> 3 then
    raise exception 'FAIL: profiles were not auto-created by on_auth_user_created';
  end if;
  if (select display_name from public.profiles where id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa') <> 'Asha Verma' then
    raise exception 'FAIL: profile display_name not copied from user metadata';
  end if;
  raise notice 'ok: profiles auto-created';
end;
$$;

insert into public.incident_reports (id, user_id, trigger_source, status, latitude, longitude,
                                     street_address, battery_level, share_token)
values
  ('a1a1a1a1-0000-4000-8000-000000000001', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'HUD_TAP', 'ACTIVE',
   28.6139, 77.2090, 'Connaught Place', 55, 'AshaTokenAbCdEfGhJkMnPq'),
  ('b1b1b1b1-0000-4000-8000-000000000001', 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 'SHAKE', 'ACTIVE',
   19.0760, 72.8777, 'Bandra', 80, 'BinaTokenAbCdEfGhJkMnPq');

insert into public.live_breadcrumbs (incident_id, latitude, longitude, battery_percentage, recorded_at)
values
  ('a1a1a1a1-0000-4000-8000-000000000001', 28.6140, 77.2091, 54, now() - interval '1 minute'),
  ('a1a1a1a1-0000-4000-8000-000000000001', 28.6141, 77.2092, 53, now()),
  ('b1b1b1b1-0000-4000-8000-000000000001', 19.0761, 72.8778, 79, now());

-- A pending invite from Asha that nobody has accepted yet.
insert into public.guardian_invites (id, owner_id, code)
values ('c1c1c1c1-0000-4000-8000-000000000001', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'K7M2Q9XZ');

do $$
begin
  if (select user_id from public.live_breadcrumbs where incident_id = 'b1b1b1b1-0000-4000-8000-000000000001' limit 1)
     <> 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb' then
    raise exception 'FAIL: breadcrumb user_id was not derived from the incident';
  end if;
  raise notice 'ok: breadcrumb owner derived from incident';
end;
$$;

-- ---------------------------------------------------------------------------
-- 1. User A cannot read or modify user B's incident
-- ---------------------------------------------------------------------------
set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa","role":"authenticated"}', true);
select set_config('request.jwt.claim.sub', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', true);

do $$
declare
  n int;
begin
  if auth.uid() <> 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'::uuid then
    raise exception 'FAIL: jwt claims not applied (auth.uid() = %)', auth.uid();
  end if;

  select count(*) into n from public.incident_reports where id = 'b1b1b1b1-0000-4000-8000-000000000001';
  if n <> 0 then raise exception 'FAIL: A can read B''s incident'; end if;

  select count(*) into n from public.incident_reports;
  if n <> 1 then raise exception 'FAIL: A should see exactly her own incident, saw %', n; end if;

  select count(*) into n from public.live_breadcrumbs where incident_id = 'b1b1b1b1-0000-4000-8000-000000000001';
  if n <> 0 then raise exception 'FAIL: A can read B''s breadcrumbs'; end if;

  update public.incident_reports set status = 'RESOLVED' where id = 'b1b1b1b1-0000-4000-8000-000000000001';
  get diagnostics n = row_count;
  if n <> 0 then raise exception 'FAIL: A updated B''s incident'; end if;

  delete from public.incident_reports where id = 'b1b1b1b1-0000-4000-8000-000000000001';
  get diagnostics n = row_count;
  if n <> 0 then raise exception 'FAIL: A deleted B''s incident'; end if;

  select count(*) into n from public.profiles where id = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
  if n <> 0 then raise exception 'FAIL: A can read B''s profile'; end if;

  raise notice 'ok: A cannot read/update/delete B''s incident';
end;
$$;

do $$
begin
  begin
    insert into public.live_breadcrumbs (incident_id, latitude, longitude)
    values ('b1b1b1b1-0000-4000-8000-000000000001', 1, 1);
    raise exception 'FAIL: A inserted a breadcrumb into B''s incident';
  exception
    when insufficient_privilege or not_null_violation or check_violation then
      raise notice 'ok: A cannot insert breadcrumbs for B''s incident';
  end;

  begin
    insert into public.incident_reports (id, user_id, trigger_source, share_token)
    values (gen_random_uuid(), 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 'HUD_TAP', 'ForgedTokenAbCdEfGhJkMn');
    raise exception 'FAIL: A inserted an incident owned by B';
  exception
    when insufficient_privilege then
      raise notice 'ok: A cannot insert an incident for B';
  end;
end;
$$;

-- Own-row writes work, and server-owned fields cannot be forged.
do $$
declare
  n int;
  sent boolean;
  tok text;
begin
  insert into public.live_breadcrumbs (incident_id, latitude, longitude, recorded_at)
  values ('a1a1a1a1-0000-4000-8000-000000000001', 28.6142, 77.2093, now() + interval '1 second');

  update public.incident_reports
     set telegram_broadcast_sent = true, share_token = 'HijackedTokenAbCdEfGhJk', street_address = 'Janpath'
   where id = 'a1a1a1a1-0000-4000-8000-000000000001';
  get diagnostics n = row_count;
  if n <> 1 then raise exception 'FAIL: A could not update her own incident'; end if;

  select telegram_broadcast_sent, share_token into sent, tok
  from public.incident_reports where id = 'a1a1a1a1-0000-4000-8000-000000000001';
  if sent then raise exception 'FAIL: client forged telegram_broadcast_sent'; end if;
  if tok <> 'AshaTokenAbCdEfGhJkMnPq' then raise exception 'FAIL: client changed share_token'; end if;

  raise notice 'ok: owner writes allowed, server fields pinned';
end;
$$;

-- rate_limits and bump_rate_limit are service-role only.
do $$
begin
  begin
    perform 1 from public.rate_limits;
    raise exception 'FAIL: authenticated can read rate_limits';
  exception when insufficient_privilege then
    raise notice 'ok: rate_limits not readable by authenticated';
  end;
  begin
    perform public.bump_rate_limit(auth.uid(), 'x', 60);
    raise exception 'FAIL: authenticated can call bump_rate_limit';
  exception when insufficient_privilege then
    raise notice 'ok: bump_rate_limit not callable by authenticated';
  end;
  begin
    insert into public.guardian_invites (owner_id, code) values (auth.uid(), 'ABCDEFGH');
    raise exception 'FAIL: authenticated can insert invites directly';
  exception when insufficient_privilege then
    raise notice 'ok: invites are created only through the edge function';
  end;
end;
$$;

reset role;

-- ---------------------------------------------------------------------------
-- 2. Guardian G: no access before acceptance, access after, none after revoke
-- ---------------------------------------------------------------------------
set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"99999999-9999-4999-8999-999999999999","role":"authenticated"}', true);
select set_config('request.jwt.claim.sub', '99999999-9999-4999-8999-999999999999', true);

do $$
declare n int;
begin
  select count(*) into n from public.incident_reports where user_id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
  if n <> 0 then raise exception 'FAIL: guardian reads incidents before acceptance'; end if;
  select count(*) into n from public.live_breadcrumbs where user_id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
  if n <> 0 then raise exception 'FAIL: guardian reads breadcrumbs before acceptance'; end if;
  select count(*) into n from public.guardian_invites;
  if n <> 0 then raise exception 'FAIL: guardian can see a pending invite she has not accepted'; end if;
  raise notice 'ok: no guardian access before acceptance';
end;
$$;

reset role;
update public.guardian_invites
   set status = 'ACCEPTED', guardian_user_id = '99999999-9999-4999-8999-999999999999', accepted_at = now()
 where id = 'c1c1c1c1-0000-4000-8000-000000000001';

set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"99999999-9999-4999-8999-999999999999","role":"authenticated"}', true);
select set_config('request.jwt.claim.sub', '99999999-9999-4999-8999-999999999999', true);

do $$
declare n int;
begin
  select count(*) into n from public.incident_reports where user_id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
  if n <> 1 then raise exception 'FAIL: accepted guardian cannot read the owner''s incident (saw %)', n; end if;

  select count(*) into n from public.live_breadcrumbs where user_id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
  if n < 2 then raise exception 'FAIL: accepted guardian cannot read the owner''s breadcrumbs (saw %)', n; end if;

  select count(*) into n from public.incident_reports where user_id = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
  if n <> 0 then raise exception 'FAIL: guardian of A can read B''s incident'; end if;

  select count(*) into n from public.profiles where id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
  if n <> 1 then raise exception 'FAIL: guardian cannot read the owner''s profile'; end if;

  update public.incident_reports set status = 'FALSE_ALARM' where id = 'a1a1a1a1-0000-4000-8000-000000000001';
  get diagnostics n = row_count;
  if n <> 0 then raise exception 'FAIL: guardian updated the owner''s incident'; end if;

  begin
    insert into public.live_breadcrumbs (incident_id, latitude, longitude)
    values ('a1a1a1a1-0000-4000-8000-000000000001', 1, 1);
    raise exception 'FAIL: guardian inserted a breadcrumb';
  exception when insufficient_privilege then
    raise notice 'ok: guardian is read-only';
  end;

  raise notice 'ok: accepted guardian can read owner incident + breadcrumbs';
end;
$$;

reset role;

-- Turning off live-location sharing removes access.
update public.guardian_invites set can_view_live_location = false
 where id = 'c1c1c1c1-0000-4000-8000-000000000001';

set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"99999999-9999-4999-8999-999999999999","role":"authenticated"}', true);
select set_config('request.jwt.claim.sub', '99999999-9999-4999-8999-999999999999', true);
do $$
begin
  if exists (select 1 from public.incident_reports where user_id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa') then
    raise exception 'FAIL: guardian still reads with can_view_live_location = false';
  end if;
  raise notice 'ok: can_view_live_location = false blocks guardian';
end;
$$;
reset role;

-- Revocation removes access.
update public.guardian_invites
   set can_view_live_location = true, status = 'REVOKED', revoked_at = now()
 where id = 'c1c1c1c1-0000-4000-8000-000000000001';

set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"99999999-9999-4999-8999-999999999999","role":"authenticated"}', true);
select set_config('request.jwt.claim.sub', '99999999-9999-4999-8999-999999999999', true);
do $$
begin
  if exists (select 1 from public.incident_reports where user_id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa')
     or exists (select 1 from public.live_breadcrumbs where user_id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa') then
    raise exception 'FAIL: revoked guardian still has access';
  end if;
  raise notice 'ok: revoked guardian loses access';
end;
$$;
reset role;

-- ---------------------------------------------------------------------------
-- 3. anon: can call track_incident, cannot select any table
-- ---------------------------------------------------------------------------
set local role anon;
select set_config('request.jwt.claims', '{"role":"anon"}', true);
select set_config('request.jwt.claim.sub', '', true);

do $$
declare
  r jsonb;
  t text;
begin
  r := public.track_incident('AshaTokenAbCdEfGhJkMnPq');
  if r is null then raise exception 'FAIL: track_incident returned null for a valid token'; end if;
  if r ->> 'first_name' <> 'Asha' then raise exception 'FAIL: expected first name only, got %', r ->> 'first_name'; end if;
  if r ->> 'status' <> 'ACTIVE' then raise exception 'FAIL: wrong status %', r ->> 'status'; end if;
  if r ->> 'trigger_label' <> 'SOS button' then raise exception 'FAIL: wrong trigger label'; end if;
  if jsonb_array_length(r -> 'breadcrumbs') < 2 then raise exception 'FAIL: breadcrumbs missing'; end if;
  if r ? 'user_id' or r ? 'id' or r ? 'share_token' or r ? 'covert' then
    raise exception 'FAIL: track_incident leaks private fields: %', r;
  end if;

  if public.track_incident('NoSuchTokenAbCdEfGhJkMn') is not null then
    raise exception 'FAIL: unknown token returned data';
  end if;
  if public.track_incident('%') is not null or public.track_incident('') is not null
     or public.track_incident(null) is not null then
    raise exception 'FAIL: malformed token returned data';
  end if;
  if public.track_incident('AshaToken%') is not null then
    raise exception 'FAIL: wildcard token matched';
  end if;

  foreach t in array array['profiles', 'emergency_contacts', 'incident_reports', 'live_breadcrumbs',
                           'safe_zones', 'guardian_invites', 'push_tokens', 'rate_limits'] loop
    begin
      execute format('select 1 from public.%I limit 1', t);
      raise exception 'FAIL: anon can select from %', t;
    exception when insufficient_privilege then
      null;
    end;
  end loop;

  raise notice 'ok: anon can track by token but cannot select tables';
end;
$$;

reset role;

-- An incident resolved more than 24 h ago is no longer trackable.
alter table public.incident_reports disable trigger trg_incidents_before_update;
update public.incident_reports
   set status = 'RESOLVED', resolved_at = now() - interval '25 hours', updated_at = now() - interval '25 hours'
 where id = 'b1b1b1b1-0000-4000-8000-000000000001';
alter table public.incident_reports enable trigger trg_incidents_before_update;

set local role anon;
do $$
begin
  if public.track_incident('BinaTokenAbCdEfGhJkMnPq') is not null then
    raise exception 'FAIL: incident resolved > 24 h ago is still trackable';
  end if;
  raise notice 'ok: stale resolved incidents are not trackable';
end;
$$;
reset role;

-- Service-side limiter behaves as a fixed window.
do $$
declare c int;
begin
  c := public.bump_rate_limit('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'test', 60);
  c := public.bump_rate_limit('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'test', 60);
  if c <> 2 then raise exception 'FAIL: bump_rate_limit expected 2, got %', c; end if;
  update public.rate_limits set window_start = now() - interval '2 minutes'
   where user_id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa' and bucket = 'test';
  c := public.bump_rate_limit('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'test', 60);
  if c <> 1 then raise exception 'FAIL: window did not reset, got %', c; end if;
  raise notice 'ok: bump_rate_limit fixed window';
end;
$$;

-- Schema invariants.
do $$
begin
  begin
    insert into public.incident_reports (user_id, trigger_source, share_token)
    values ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'HUD_TAP', 'tooShort');
    raise exception 'FAIL: short share_token accepted';
  exception when check_violation then
    raise notice 'ok: share_token length enforced';
  end;
  begin
    insert into public.incident_reports (user_id, trigger_source, share_token)
    values ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'PANIC', 'ValidTokenAbCdEfGhJkMnPq');
    raise exception 'FAIL: unknown trigger_source accepted';
  exception when check_violation then
    raise notice 'ok: trigger_source enforced';
  end;
  if exists (select 1 from pg_class where relname = 'rate_limits' and relnamespace = 'public'::regnamespace
             and not relrowsecurity) then
    raise exception 'FAIL: RLS disabled on rate_limits';
  end if;
end;
$$;

rollback;
