-- Make /s/{code} resolve a store link to its human-readable `slug` instead of
-- the raw uuid, so the in-app destination becomes /personal/shop/store/{slug}
-- (the store fetch already resolves uuid-or-slug). short_links.target_id stays
-- the canonical uuid — slugs can change, uuids can't, so resolution joins to
-- store_profiles at read time rather than denormalising the slug into the link.
--
-- The return column target_id changes uuid -> text (a slug is text), which a
-- CREATE OR REPLACE cannot do, so drop and recreate. Product links keep
-- returning the uuid as text; stores fall back to the uuid when slug is null.

drop function if exists public.record_link_open(text, text, text);

create or replace function public.record_link_open(
  p_code text, p_platform text, p_source text
) returns table (target_type text, target_id text)
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
begin
  insert into public.link_events (code, source, user_id, platform)
    values (p_code, coalesce(p_source, 'app'), v_uid, p_platform);

  return query
    select
      sl.target_type,
      case
        when sl.target_type = 'store' then coalesce(sp.slug, sl.target_id::text)
        else sl.target_id::text
      end as target_id
    from public.short_links sl
    left join public.store_profiles sp
      on sl.target_type = 'store' and sp.id = sl.target_id
    where sl.code = p_code and sl.is_active;
end; $$;

grant execute on function public.record_link_open(text, text, text) to authenticated;
