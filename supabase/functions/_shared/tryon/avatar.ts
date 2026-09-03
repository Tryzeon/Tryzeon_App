import { getAvatarPath } from "../user-profile.ts";
import { MissingAvatarError } from "./errors.ts";
import type { ImageSource } from "./types.ts";
import type { DbClient } from "../supabase.ts";

export async function resolveStoredAvatar(
  client: DbClient,
  userId: string,
): Promise<ImageSource> {
  const path = await getAvatarPath(client, userId);
  if (!path) throw new MissingAvatarError("no avatar on profile");
  return { path };
}
