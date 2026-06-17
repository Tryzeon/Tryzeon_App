-- Rate limiting moved from Postgres (rate_limit_counters + check_rate_limit)
-- to Upstash Redis, whose key TTLs auto-expire counters. That removes the need
-- for the rate_limit_counters table, its RPC, and the cleanup function entirely.
drop function if exists public.cleanup_old_rate_limit_counters();
drop function if exists public.check_rate_limit(uuid, text, integer, integer);
drop table if exists public.rate_limit_counters;

-- Quota counters (user_daily_usage) stay in Postgres: they are billing/quota
-- business data, not abuse-prevention. cleanup_old_daily_usage already existed
-- but was never scheduled, so the table grew unbounded. Schedule it daily at
-- 03:00 UTC to prune rows older than 30 days.
select cron.unschedule('cleanup-old-daily-usage')
where exists (select 1 from cron.job where jobname = 'cleanup-old-daily-usage');

select cron.schedule(
  'cleanup-old-daily-usage',
  '0 3 * * *',
  $$ select public.cleanup_old_daily_usage(); $$
);
