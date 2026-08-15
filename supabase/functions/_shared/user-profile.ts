/**
 * Access to the `user_profiles` row, in one place.
 *
 * The avatar path was previously read by `line-webhook` and written by
 * `liff-avatar`, and the profile fields were projected by `chat` — each naming
 * the table and columns itself, so the "blank counts as unset" rule lived only
 * on one read and a rename meant editing three functions. All of it now goes
 * through this module.
 *
 * The boundary is deliberate: column vocabulary stops here, meaning does not
 * start here. What an `age_range` bucket says to a user, or whether a missing
 * profile should fail a request, is the consumer's business — this module hands
 * back the values and nothing more, so it does not accrete one accessor per
 * caller.
 */
import { SupabaseClient } from "jsr:@supabase/supabase-js@2";
import { nonEmptyStr } from "./text.ts";

export const USER_PROFILES_TABLE = "user_profiles";

const AVATAR_PATH_COLUMN = "avatar_path";

/** Columns `getUserProfile` projects; kept beside the mapping that reads them. */
const PROFILE_COLUMNS = "name, gender, age_range, style_preferences";

/** The user's stored profile fields, normalized but uninterpreted. */
export interface UserProfile {
  name: string | null;
  gender: string | null;
  /** Raw bucket code (e.g. `25_34`); consumers own what it renders as. */
  ageRange: string | null;
  stylePreferences: string[];
}

/**
 * The user's stored model photo path, or null when none is set. A blank value
 * is normalized to null so callers have a single "not onboarded yet" check.
 */
export async function getAvatarPath(
  client: SupabaseClient,
  userId: string,
): Promise<string | null> {
  const { data, error } = await client
    .from(USER_PROFILES_TABLE)
    .select(AVATAR_PATH_COLUMN)
    .eq("user_id", userId)
    .maybeSingle();
  if (error) {
    throw new Error(`${AVATAR_PATH_COLUMN} lookup failed: ${error.message}`);
  }
  return nonEmptyStr(data?.[AVATAR_PATH_COLUMN]);
}

/**
 * The user's profile fields, or null when they have no profile row. Raises on a
 * lookup failure rather than reporting it as "no profile": a caller that treats
 * a missing profile as benign must not be handed that answer for an RLS or
 * connection fault, so whether to degrade or fail stays its decision to make.
 */
export async function getUserProfile(
  client: SupabaseClient,
  userId: string,
): Promise<UserProfile | null> {
  const { data, error } = await client
    .from(USER_PROFILES_TABLE)
    .select(PROFILE_COLUMNS)
    .eq("user_id", userId)
    .maybeSingle();
  if (error) {
    throw new Error(`user profile lookup failed: ${error.message}`);
  }
  if (!data) return null;

  return {
    name: nonEmptyStr(data.name),
    gender: nonEmptyStr(data.gender),
    ageRange: nonEmptyStr(data.age_range),
    stylePreferences: Array.isArray(data.style_preferences)
      ? data.style_preferences.filter((s): s is string => typeof s === "string")
      : [],
  };
}

/** Points the user's profile at a newly uploaded model photo. */
export async function setAvatarPath(
  client: SupabaseClient,
  userId: string,
  path: string,
): Promise<void> {
  const { error } = await client
    .from(USER_PROFILES_TABLE)
    .update({ [AVATAR_PATH_COLUMN]: path })
    .eq("user_id", userId);
  if (error) {
    throw new Error(`${AVATAR_PATH_COLUMN} update failed: ${error.message}`);
  }
}
