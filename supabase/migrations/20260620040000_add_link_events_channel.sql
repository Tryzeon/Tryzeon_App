-- Acquisition channel for a short-link open: which app/surface the click came
-- from. Today derived best-effort from the User-Agent of the in-app browser
-- (Instagram, Facebook, Messenger, Threads, LINE, …) by the resolve-link edge
-- function; an explicit `?src=` tag can override it later for exact attribution.
-- Nullable: legacy rows and undetectable opens stay NULL rather than guessing.
alter table public.link_events add column if not exists channel text;

create index if not exists link_events_channel_idx on public.link_events(channel);
