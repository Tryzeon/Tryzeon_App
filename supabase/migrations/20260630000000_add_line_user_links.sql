-- Maps a LINE userId (id_token `sub`) to a Supabase auth user.
-- Written/read ONLY by the liff-tryon Edge Function via the service role.
create table if not exists public.line_user_links (
  line_user_id text primary key,
  user_id      uuid not null references auth.users(id) on delete cascade,
  created_at   timestamptz not null default now()
);

create index if not exists line_user_links_user_id_idx
  on public.line_user_links (user_id);

-- RLS on with NO policies: anon/authenticated get zero rows.
-- The service role bypasses RLS, which is the only caller.
alter table public.line_user_links enable row level security;

grant all on table public.line_user_links to service_role;
