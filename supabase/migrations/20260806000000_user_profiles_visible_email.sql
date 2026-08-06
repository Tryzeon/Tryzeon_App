-- `user_profiles.email` has existed unwritten since the baseline. Fill it, so a
-- client can render an address without first working out whether the one on
-- `auth.users` is real.
--
-- Two kinds are not. A LINE account's is synthesized by `_shared/line-user.ts`
-- only so GoTrue has something to key a session on, and Apple's Hide My Email
-- hands back an opaque relay. Deciding that here keeps the synthetic format
-- known to the backend that mints it: a client matching on the domain itself
-- would ship the rule in a binary that a later change to it cannot reach.

create or replace function public.visible_email(p_email text)
returns text
language sql
immutable
as $$
  select case
    when p_email is null or p_email = '' then null
    when p_email like '%@liff.tryzeon.app' then null
    when p_email like '%@privaterelay.appleid.com' then null
    else p_email
  end;
$$;

create or replace function public.handle_new_user() returns trigger
    language plpgsql security definer
    as $$
begin
  insert into public.user_profiles (user_id, name, email)
  values (
    new.id,
    coalesce(
      new.raw_user_meta_data->>'name',
      new.raw_user_meta_data->>'full_name',
      nullif(split_part(new.email, '@', 1), ''),
      '使用者'
    ),
    public.visible_email(new.email)
  );

  insert into public.subscriptions (user_id)
  values (new.id);

  return new;
end;$$;

update public.user_profiles p
set email = public.visible_email(u.email)
from auth.users u
where u.id = p.user_id
  and p.email is distinct from public.visible_email(u.email);
