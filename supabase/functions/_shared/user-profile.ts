/**
 * Access to the `user_profiles` row, in one place.
 *
 * The avatar path was previously read by `line-webhook` and written by an edge
 * function of its own, and the profile fields were projected by `chat` — each
 * naming the table and columns itself, so the "blank counts as unset" rule
 * lived only on one read and a rename meant editing three functions. Every
 * server-side reader now goes through this module. (The LIFF web app writes
 * `avatar_path` straight from the browser under RLS, so it is not one of them.)
 *
 * The boundary is deliberate: column vocabulary stops here, meaning does not
 * start here. What an `age_range` bucket says to a user, or whether a missing
 * profile should fail a request, is the consumer's business — this module hands
 * back the values and nothing more, so it does not accrete one accessor per
 * caller.
 */
import { nonEmptyStr, textArrayValues } from "./text.ts";
import type { Enums } from "./database.types.ts";
import type { DbClient } from "./supabase.ts";

export const USER_PROFILES_TABLE = "user_profiles";

/**
 * The shopper's own body dimensions, as stored in `user_profiles.measurements`.
 * Every field is optional — the profile form lets a shopper fill in as few as
 * they like. Lengths and circumferences are centimeters; `weight` is kilograms.
 */
export interface BodyMeasurements {
  height?: number;
  weight?: number;
  shoulder?: number;
  chest?: number;
  waist?: number;
  hips?: number;
  thigh?: number;
}

const AVATAR_PATH_COLUMN = "avatar_path";

const MEASUREMENTS_COLUMN = "measurements";

/** Columns `getUserProfile` projects; kept beside the mapping that reads them. */
const PROFILE_COLUMNS = "name, gender, age_range, style_preferences";

/** The user's stored profile fields, normalized but uninterpreted. */
export interface UserProfile {
  name: string | null;
  gender: Enums<"user_gender"> | null;
  /** Raw bucket code (e.g. `25_34`); consumers own what it renders as. */
  ageRange: string | null;
  stylePreferences: string[];
}

/**
 * The user's stored model photo path, or null when none is set. A blank value
 * is normalized to null so callers have a single "not onboarded yet" check.
 */
export async function getAvatarPath(
  client: DbClient,
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
 * The shopper's recorded body dimensions, or null when they have none.
 *
 * Deliberately separate from `getUserProfile`: chat projects that row on every
 * message and has no use for measurements, so this column stays out of
 * `PROFILE_COLUMNS`. Raises on a lookup failure rather than reporting it as
 * "no measurements" — degrading is the caller's decision, not this module's.
 */
export async function getBodyMeasurements(
  client: DbClient,
  userId: string,
): Promise<BodyMeasurements | null> {
  const { data, error } = await client
    .from(USER_PROFILES_TABLE)
    .select(MEASUREMENTS_COLUMN)
    .eq("user_id", userId)
    .maybeSingle();
  if (error) {
    throw new Error(`${MEASUREMENTS_COLUMN} lookup failed: ${error.message}`);
  }
  const raw = data?.[MEASUREMENTS_COLUMN];
  if (typeof raw !== "object" || raw === null) return null;
  return raw as BodyMeasurements;
}

/**
 * The user's profile fields, or null when they have no profile row. Raises on a
 * lookup failure rather than reporting it as "no profile": a caller that treats
 * a missing profile as benign must not be handed that answer for an RLS or
 * connection fault, so whether to degrade or fail stays its decision to make.
 */
export async function getUserProfile(
  client: DbClient,
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
    gender: data.gender,
    ageRange: nonEmptyStr(data.age_range),
    stylePreferences: textArrayValues(data.style_preferences),
  };
}
