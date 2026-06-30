import { SupabaseClient } from "jsr:@supabase/supabase-js@2";
import { LineProfile } from "./line.ts";

const SYNTHETIC_EMAIL_DOMAIN = "liff.tryzeon.app";

/**
 * Maps a verified LINE profile to a stable Supabase auth user id.
 * Looks up line_user_links; on a miss, mints a new auth user keyed by the
 * synthetic email `line_<sub>@liff.tryzeon.app` and records the mapping.
 */
export async function resolveSupabaseUser(
  admin: SupabaseClient,
  profile: LineProfile,
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

  const { data: created, error: createError } = await admin.auth.admin.createUser({
    email: `line_${profile.sub}@${SYNTHETIC_EMAIL_DOMAIN}`,
    email_confirm: true,
    app_metadata: { provider: "line", line_user_id: profile.sub },
    user_metadata: profile.name ? { name: profile.name } : {},
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
