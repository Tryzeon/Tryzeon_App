-- link_events.user_id originally referenced auth.users with the default
-- ON DELETE NO ACTION. That blocked auth user deletion (delete-account edge
-- function) with a foreign-key violation whenever the user had any logged-in
-- short-link opens, surfacing as an HTTP 500 / AuthRetryableFetchError.
--
-- Switch to ON DELETE SET NULL so deleting an account anonymizes the user's
-- open events (user_id is already nullable for anonymous web opens) while
-- preserving open-count analytics.
alter table public.link_events
  drop constraint if exists link_events_user_id_fkey;

alter table public.link_events
  add constraint link_events_user_id_fkey
  foreign key (user_id) references auth.users (id) on delete set null;
