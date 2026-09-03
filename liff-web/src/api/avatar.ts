import { currentUserId } from "../lib/auth";
import { downscaleToBlob, JPEG_EXTENSION, JPEG_MIME } from "../lib/image";
import { supabase } from "../lib/supabase";

const AVATARS_BUCKET = "user-avatars";
// Longer than the app's one hour: home stays mounted inside the tab shell, so
// the signed URL has to outlive the whole LIFF session rather than just lasting
// until the next remount.
const SIGNED_URL_TTL_SECONDS = 86400;

/**
 * The first path segment is the userId — a requirement, not a convention: the
 * bucket policy demands `(storage.foldername(name))[1] = auth.uid()`, and
 * getting it wrong makes the upload fail. So the userId can only come from the
 * session.
 */
export async function setAvatar(file: File): Promise<string> {
  const userId = await currentUserId();
  const blob = await downscaleToBlob(file);
  const path = `${userId}/avatar/${Date.now()}.${JPEG_EXTENSION}`;

  const { error: uploadError } = await supabase.storage
    .from(AVATARS_BUCKET)
    .upload(path, blob, { contentType: JPEG_MIME, upsert: true });
  if (uploadError) throw uploadError;

  const { error: profileError } = await supabase
    .from("user_profiles")
    .update({ avatar_path: path })
    .eq("user_id", userId);
  if (profileError) throw profileError;

  return path;
}

export async function avatarUrl(path: string): Promise<string> {
  const { data, error } = await supabase.storage
    .from(AVATARS_BUCKET)
    .createSignedUrl(path, SIGNED_URL_TTL_SECONDS);
  if (error) throw error;
  return data.signedUrl;
}
