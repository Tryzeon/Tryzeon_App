-- short_links moves from a polymorphic (target_type, target_id) pair to a typed
-- FK store_id.
--
-- Why: Postgres cannot put a foreign key on a polymorphic pair, so target_id
-- could point at a store that does not exist without anyone noticing — and a
-- printed QR would simply be dead. A typed FK makes the DB guarantee the target
-- exists. Supporting product links later goes through an exclusive arc: make
-- store_id nullable, add product_id, add
-- check (num_nonnulls(store_id, product_id) = 1).
--
-- At the same time:
--   * drop forward_url — the old deferred deep link platform is gone, and a
--     free-text URL is a source of open redirects
--   * metadata jsonb becomes note text — the name/store it used to hold are both
--     derivable from code and store_profiles; the only thing that is not is the
--     note saying where the code is printed
--   * code gets a lowercase format check — the PK used to be case sensitive, so
--     PinkyRabbit and pinkyrabbit were two rows
--   * open_with declares where this link should open. A link supports exactly one
--     open method, so this is a property of the link and does not change with the
--     scanning environment — the environment only decides whether a plain 302
--     works, not where it goes. Only liff is implemented; web and app each get
--     their own value later, and the check widens along with them. Restricting it
--     to implemented values means the database cannot hold a state the code
--     cannot handle yet — the same reason store_id is a typed FK. The default
--     exists so the QR-creation flow need not know about this column until there
--     really is a second open method.
--   * link_events.code's FK gains on delete cascade — otherwise deleting a store
--     is blocked by the FK and turns into an HTTP 500, the same class of problem
--     as link_events.user_id, fixed in 20260619000000
--
-- short_links currently holds no data (link_events.code has an FK on it, so the
-- events table is empty too), so it is rebuilt outright rather than migrated
-- column by column.

alter table public.link_events drop constraint if exists link_events_code_fkey;

drop table if exists public.short_links;

create table public.short_links (
  code       text primary key,
  store_id   uuid not null references public.store_profiles(id) on delete cascade,
  open_with  text not null default 'liff',
  is_active  boolean not null default true,
  note       text,
  created_at timestamptz not null default now(),
  constraint short_links_code_format check (code ~ '^[a-z0-9][a-z0-9-]{1,31}$'),
  constraint short_links_open_with_check check (open_with in ('liff'))
);

alter table public.short_links enable row level security;
-- Only service_role (the resolve-link edge function) touches this table. No
-- policy => anon/authenticated are denied by default.

alter table public.link_events
  add constraint link_events_code_fkey
  foreign key (code) references public.short_links(code)
  on update cascade on delete cascade;

-- record_link_open existed for in-app resolution of /s/{code}, but QR codes now
-- land in LIFF and the app-side resolver has been deleted, so this RPC has no
-- callers left.
--
-- Older installed app binaries still intercept /s/ and call it, and those calls
-- will fail — resolveShortLinkDestination on that path catches the error and
-- falls back to the home page. This degradation is accepted deliberately:
-- keeping an unmaintained RPC alive for versions that have not updated is exactly
-- the backward-compat baggage we avoid. Updated versions no longer claim /s/, so
-- scanning takes the user to the browser and LIFF as intended.
drop function if exists public.record_link_open(text, text, text);
