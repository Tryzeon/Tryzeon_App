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

const PROFILE_COLUMNS = "name, gender, age_range, style_preferences";

export interface UserProfile {
  name: string | null;
  gender: Enums<"user_gender"> | null;
  /** Raw bucket code (e.g. `25_34`); consumers own what it renders as. */
  ageRange: string | null;
  stylePreferences: string[];
}

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
