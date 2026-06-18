-- One row per short-link open (a QR scan, a shared-link tap, a campaign click…).
--   source='web'      : anonymous open logged by the resolve-link edge function
--                       (device had no app installed -> forwarded to platform).
--   source='app'      : installed user opened the link, App Link opened the app.
--   source='deferred' : delivered by the ChottuLink SDK after a deferred install.
-- 'paid_ad' is reserved for a future MMP integration on paid acquisition channels.
-- Named to parallel public.analytics_events.
create table if not exists public.link_events (
  id uuid primary key default gen_random_uuid(),
  code text not null references public.short_links(code),
  source text not null,
  user_id uuid references auth.users,
  platform text,
  created_at timestamptz not null default now()
);

create index if not exists link_events_code_idx on public.link_events(code);

alter table public.link_events enable row level security;
-- Written only via the resolve-link edge function (service_role) and the
-- record_link_open RPC (SECURITY DEFINER). No policies => default deny.
-- Open counts are computed on demand: select count(*) ... where code = ?.

-- Records an identified open from inside the app (installed open or deferred
-- install) and resolves the code to its destination so the app can navigate.
create or replace function public.record_link_open(
  p_code text, p_platform text, p_source text
) returns table (target_type text, target_id uuid)
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
begin
  insert into public.link_events (code, source, user_id, platform)
    values (p_code, coalesce(p_source, 'app'), v_uid, p_platform);

  return query
    select sl.target_type, sl.target_id
    from public.short_links sl
    where sl.code = p_code and sl.is_active;
end; $$;

grant execute on function public.record_link_open(text, text, text) to authenticated;
