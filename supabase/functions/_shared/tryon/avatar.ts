import { SupabaseClient } from "jsr:@supabase/supabase-js@2";
import { getAvatarPath } from "../user-profile.ts";
import { MissingAvatarError } from "./errors.ts";
import type { ImageSource } from "./types.ts";

/**
 * The model photo on the user's profile.
 *
 * The counterpart of `resolveProductGarment`: both turn a reference the caller
 * cannot name into trusted material. That is why the avatar has no path on the
 * wire — a client copy of the path is a copy of the truth, and it goes stale.
 */
export async function resolveStoredAvatar(
  client: SupabaseClient,
  userId: string,
): Promise<ImageSource> {
  const path = await getAvatarPath(client, userId);
  if (!path) throw new MissingAvatarError("no avatar on profile");
  return { path };
}
