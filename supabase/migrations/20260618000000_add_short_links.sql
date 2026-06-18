-- Tracked short-link definitions. The general namespace behind tryzeon.com/s/{code}
-- (QR codes today; in-app shares, campaign and referral links later). One row maps
-- {code} -> destination, so the underlying deep-link platform can be swapped later
-- without reprinting any QR or reissuing any link.
create table if not exists public.short_links (
  code text primary key,
  target_type text not null check (target_type in ('product', 'store')),
  target_id uuid not null,
  -- Platform link (e.g. ChottuLink) we 302-forward not-installed traffic to for
  -- deferred deep linking. Never printed; only an intermediate redirect hop.
  -- Generic name so the platform can change without a schema change.
  forward_url text,
  -- Attribution / extension context (e.g. {"branch":"...","partner":"...","campaign":"..."}).
  -- jsonb so new dimensions can be added without a migration.
  metadata jsonb not null default '{}'::jsonb,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

alter table public.short_links enable row level security;
-- Only service_role (resolve-link edge function) and SECURITY DEFINER RPCs read
-- this table. No policies => default deny for anon/authenticated direct access.
