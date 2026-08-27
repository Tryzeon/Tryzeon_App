import { currentUserId } from "../lib/auth";
import { downscaleToBlob, JPEG_EXTENSION, JPEG_MIME } from "../lib/image";
import { supabase } from "../lib/supabase";

const AVATARS_BUCKET = "user-avatars";

/**
 * 儲存使用者的 model 照,之後每一次試穿都用它。
 *
 * 路徑第一段是 userId,不是慣例而是條件:bucket policy 要求
 * `(storage.foldername(name))[1] = auth.uid()`,寫錯就上傳不了。所以 userId
 * 只能來自 session。
 */
export async function setAvatar(file: File): Promise<void> {
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
}
