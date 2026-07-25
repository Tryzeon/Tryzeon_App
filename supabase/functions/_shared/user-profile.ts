/**
 * Access to the `user_profiles` row, in one place.
 *
 * The avatar path was previously read by `line-webhook` and written by
 * `liff-avatar`, each naming the table and column itself — so the "blank counts
 * as unset" rule lived only on the read side and a rename meant editing two
 * functions. Both now go through this module.
 */
import { SupabaseClient } from "jsr:@supabase/supabase-js@2";

export const USER_PROFILES_TABLE = "user_profiles";

const AVATAR_PATH_COLUMN = "avatar_path";

/**
 * The user's stored model photo path, or null when none is set. A blank value
 * is normalized to null so callers have a single "not onboarded yet" check.
 */
export async function getAvatarPath(
  admin: SupabaseClient,
  userId: string,
): Promise<string | null> {
  const { data, error } = await admin
    .from(USER_PROFILES_TABLE)
    .select(AVATAR_PATH_COLUMN)
    .eq("user_id", userId)
    .maybeSingle();
  if (error) {
    throw new Error(`${AVATAR_PATH_COLUMN} lookup failed: ${error.message}`);
  }
  const path = data?.[AVATAR_PATH_COLUMN];
  return typeof path === "string" && path.length > 0 ? path : null;
}

/** Points the user's profile at a newly uploaded model photo. */
export async function setAvatarPath(
  admin: SupabaseClient,
  userId: string,
  path: string,
): Promise<void> {
  const { error } = await admin
    .from(USER_PROFILES_TABLE)
    .update({ [AVATAR_PATH_COLUMN]: path })
    .eq("user_id", userId);
  if (error) {
    throw new Error(`${AVATAR_PATH_COLUMN} update failed: ${error.message}`);
  }
}
