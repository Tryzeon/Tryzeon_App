import { LineProfile } from "./line-identity.ts";
import type { DbClient } from "./supabase.ts";

const SYNTHETIC_EMAIL_DOMAIN = "liff.tryzeon.app";

export async function getOrCreateUserId(
  admin: DbClient,
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
