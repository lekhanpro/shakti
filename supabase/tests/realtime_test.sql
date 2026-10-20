-- Run after migrations against the disposable local CI database only.
begin;
do $$
begin
  if not exists (
    select 1 from pg_trigger
    where tgname = 'tracker_incident_changed' and not tgisinternal
      and tgrelid = 'public.incident_reports'::regclass
  ) then raise exception 'Missing incident refresh trigger'; end if;
  if not exists (
    select 1 from pg_trigger
    where tgname = 'tracker_breadcrumb_changed' and not tgisinternal
      and tgrelid = 'public.live_breadcrumbs'::regclass
  ) then raise exception 'Missing breadcrumb refresh trigger'; end if;
  if has_function_privilege('anon', 'public.notify_tracker_change()', 'EXECUTE') then
    raise exception 'Anonymous callers must not execute the notification trigger';
  end if;
  if has_table_privilege('anon', 'public.incident_reports', 'SELECT')
     or has_table_privilege('anon', 'public.live_breadcrumbs', 'SELECT') then
    raise exception 'Realtime must not grant anonymous row access';
  end if;
  if not has_function_privilege('anon', 'public.track_incident(text)', 'EXECUTE') then
    raise exception 'Token-scoped RPC must remain available';
  end if;
end;
$$;
rollback;
