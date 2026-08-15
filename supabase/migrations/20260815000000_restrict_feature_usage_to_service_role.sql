-- Take the quota RPCs away from anon and authenticated.
--
-- `increment_feature_usage` / `decrement_feature_usage` are SECURITY DEFINER and
-- take the user to charge as a parameter, so EXECUTE on them is the right to
-- write *any* user's quota row. Both were granted to `anon` and `authenticated`
-- (baseline dump, carried through every later CREATE OR REPLACE, which preserves
-- an existing function's ACL). With the public anon key — which ships inside the
-- app — that meant anyone could refund their own quota without limit, or burn
-- through someone else's.
--
-- Nothing loses a capability it was using: only the Edge Functions charge quota,
-- and they call these through the service role. No trigger or other routine
-- calls them either.
--
-- PUBLIC is revoked as well. Postgres grants EXECUTE to PUBLIC on every new
-- function, so revoking the two named roles alone would leave exactly the same
-- access reachable through it.

REVOKE ALL ON FUNCTION public.increment_feature_usage("p_user_id" uuid, "p_feature_name" text)
  FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.decrement_feature_usage("p_user_id" uuid, "p_feature_name" text)
  FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION public.increment_feature_usage("p_user_id" uuid, "p_feature_name" text)
  TO service_role;
GRANT EXECUTE ON FUNCTION public.decrement_feature_usage("p_user_id" uuid, "p_feature_name" text)
  TO service_role;

-- NOTE for whoever edits these next: CREATE OR REPLACE keeps the ACL above, but
-- DROP + CREATE does not — the schema's ALTER DEFAULT PRIVILEGES would re-grant
-- them to anon and authenticated. If you ever have to change a signature, repeat
-- these four statements in the same migration.
