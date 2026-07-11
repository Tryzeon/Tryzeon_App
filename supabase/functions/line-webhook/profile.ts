import { SupabaseClient } from "jsr:@supabase/supabase-js@2";

/** Returns the user's stored model photo path, or null if none is set. */
export async function getAvatarPath(
  admin: SupabaseClient,
  userId: string,
): Promise<string | null> {
  const { data, error } = await admin
    .from("user_profiles")
    .select("avatar_path")
    .eq("user_id", userId)
    .maybeSingle();
  if (error) {
    throw new Error(`avatar_path lookup failed: ${error.message}`);
  }
  const p = data?.avatar_path;
  return typeof p === "string" && p.length > 0 ? p : null;
}
