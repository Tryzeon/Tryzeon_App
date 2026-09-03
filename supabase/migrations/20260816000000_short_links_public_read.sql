-- Lets the short-links edge function switch to the anon key.
--
-- The endpoint is entirely public: someone scans a QR code, with no session at
-- all. It does exactly two things — look up one active short_links row and
-- record one open event — and neither needs to bypass RLS. Holding a service
-- role key meant an endpoint anyone can call held permissions over the whole
-- database.

-- Read: only is_active rows are exposed. A disabled link simply does not exist
-- for anonymous callers, the same semantics as the endpoint's 404.
create policy "Anyone can resolve an active short link"
  on public.short_links for select
  using (is_active);

-- Write: anyone may add an open event, but nobody may claim an event belongs to
-- a particular user.
--
-- Whether an anonymous caller can fabricate events is not something this policy
-- can prevent — the endpoint is public, and a loop against it has the same
-- effect. The only field worth guarding is user_id: it is the one value that
-- cannot be inferred from the User-Agent and that would poison attribution.
-- source / platform / channel are best-effort guesses from a spoofable
-- User-Agent to begin with, so restricting them would prevent nothing.
--
-- No path currently writes an event carrying a user_id (record_link_open was
-- removed in 20260811000000), so this restriction blocks no existing write.
create policy "Anyone can record a link open"
  on public.link_events for insert
  with check (user_id is null);

-- link_events deliberately gets no select policy: writable, not readable. The
-- edge function's insert uses return=minimal and needs nothing back, and open
-- counts are aggregated by the backend with the service role.
