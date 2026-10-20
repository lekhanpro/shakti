-- Empty invalidations on unguessable token topics. Sensitive rows remain
-- accessible only through track_incident(); existing table RLS is unchanged.
create or replace function public.notify_tracker_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  incident public.incident_reports%rowtype;
begin
  if tg_table_name = 'incident_reports' then
    if tg_op = 'DELETE' then incident := old; else incident := new; end if;
  else
    select * into incident from public.incident_reports where id = new.incident_id;
    if not found then return new; end if;
  end if;

  -- The same expiry rules apply to notifications and the public read RPC.
  if incident.status in ('RESOLVED', 'FALSE_ALARM')
     and coalesce(incident.resolved_at, incident.updated_at) < now() - interval '24 hours' then
    return null;
  end if;
  if incident.created_at < now() - interval '7 days'
     and coalesce(incident.resolved_at, incident.updated_at) < now() - interval '24 hours' then
    return null;
  end if;

  -- No coordinates, name, incident ID, status, or other row fields.
  -- A subscriber must still pass token validation and expiry in the RPC.
  perform realtime.send('{}'::jsonb, 'changed', 'shakti:' || incident.share_token, false);
  return null; -- AFTER trigger return values are ignored.
exception when others then
  -- Notification availability must never roll back emergency writes.
  -- The tracker continues polling when Realtime is unavailable.
  raise warning 'Tracker notification unavailable; polling remains enabled';
  return null;
end;
$$;

revoke all on function public.notify_tracker_change() from public, anon, authenticated;
drop trigger if exists tracker_incident_changed on public.incident_reports;
create trigger tracker_incident_changed
after insert or update or delete on public.incident_reports
for each row execute function public.notify_tracker_change();

drop trigger if exists tracker_breadcrumb_changed on public.live_breadcrumbs;
create trigger tracker_breadcrumb_changed
after insert on public.live_breadcrumbs
for each row execute function public.notify_tracker_change();
