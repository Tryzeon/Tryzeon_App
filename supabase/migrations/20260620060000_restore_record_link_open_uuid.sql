-- Revert 20260620050000: the short-link store-slug resolution was dropped before
-- shipping. Restore record_link_open to its original 20260618000100 shape —
-- returns target_id as uuid, no store_profiles join. The app resolves stores
-- uuid-or-slug via getStoreProfile, so the canonical uuid is all the link needs.
--
-- Migrations are forward-only, so this is a new reversing migration rather than
-- an edit/delete of 050000 (which stays on disk as applied history). The return
-- column changes text -> uuid, which CREATE OR REPLACE cannot do, so drop first.

drop function if exists public.record_link_open(text, text, text);

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
