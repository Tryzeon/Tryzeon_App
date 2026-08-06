import { SupabaseClient } from "jsr:@supabase/supabase-js@2";
import { LineProfile } from "./line-identity.ts";

const SYNTHETIC_EMAIL_DOMAIN = "liff.tryzeon.app";

/**
 * The stable auth user id for a verified LINE profile, creating one if this is
 * the first time we have seen the account.
 *
 * Named for the write, not just the read: a miss in `line_user_links` mints an
 * auth user keyed by the synthetic email `line_<sub>@liff.tryzeon.app` and
 * records the mapping, permanently binding that LINE account to an identity.
 * "Resolve" is reserved in this codebase for turning a reference into something
 * that already exists (see `_shared/tryon/sources.ts`), which this is not.
 */
export async function getOrCreateUserId(
  admin: SupabaseClient,
  profile: LineProfile,
  resolveDisplayName?: () => Promise<string | undefined>,
): Promise<string> {
  const { data: existing, error: lookupError } = await admin
    .from("line_user_links")
    .select("user_id")
    .eq("line_user_id", profile.sub)
    .maybeSingle();

  if (lookupError) {
    throw new Error(`line_user_links lookup failed: ${lookupError.message}`);
  }
  if (existing) {
    return existing.user_id as string;
  }

  let name = profile.name;
  if (!name && resolveDisplayName) {
    try {
      name = await resolveDisplayName();
    } catch (err) {
      // Cosmetic. Whoever is minting this user is mid-conversation with them.
      console.warn(`line display name lookup failed for ${profile.sub}:`, err);
    }
  }

  const { data: created, error: createError } = await admin.auth.admin.createUser({
    email: `line_${profile.sub}@${SYNTHETIC_EMAIL_DOMAIN}`,
    email_confirm: true,
    app_metadata: { provider: "line", line_user_id: profile.sub },
    user_metadata: name ? { name } : {},
  });

  if (createError || !created?.user) {
    throw new Error(`createUser failed: ${createError?.message ?? "no user returned"}`);
  }
  const userId = created.user.id;

  const { error: insertError } = await admin
    .from("line_user_links")
    .insert({ line_user_id: profile.sub, user_id: userId });

  if (insertError) {
    throw new Error(`line_user_links insert failed: ${insertError.message}`);
  }

  return userId;
}
