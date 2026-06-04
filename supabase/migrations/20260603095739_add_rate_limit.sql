create table if not exists public.rate_limit_counters (
  user_id uuid not null,
  bucket text not null,
  window_start timestamptz not null,
  count integer not null default 0,
  primary key (user_id, bucket, window_start)
);

alter table public.rate_limit_counters enable row level security;
-- Only service_role via the RPC accesses this table. No policies => default deny for users.

create or replace function public.check_rate_limit(
  p_user_id uuid, p_bucket text, p_limit integer, p_window_seconds integer
) returns boolean
language plpgsql security definer set search_path = public as $$
declare
  v_window_start timestamptz;
  v_count integer;
begin
  v_window_start := to_timestamp(
    floor(extract(epoch from now()) / p_window_seconds) * p_window_seconds
  );
  insert into public.rate_limit_counters(user_id, bucket, window_start, count)
    values (p_user_id, p_bucket, v_window_start, 1)
  on conflict (user_id, bucket, window_start)
    do update set count = rate_limit_counters.count + 1
    where rate_limit_counters.count < p_limit
  returning count into v_count;
  return v_count is not null;
end; $$;

grant execute on function public.check_rate_limit(uuid, text, integer, integer) to service_role;

create or replace function public.cleanup_old_rate_limit_counters() returns void
language plpgsql security definer set search_path = public as $$
begin
  delete from public.rate_limit_counters
  where window_start < now() - interval '2 days';
end; $$;
