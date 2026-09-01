import { currentUserId } from "../lib/auth";
import { downscaleToBlob, JPEG_EXTENSION, JPEG_MIME } from "../lib/image";
import { supabase } from "../lib/supabase";

const AVATARS_BUCKET = "user-avatars";
// 比 app 的一小時長:首頁在分頁殼裡一直掛著,那張簽章網址要撐過整個 LIFF session,
// 而不是撐到下一次重新掛載為止。
const SIGNED_URL_TTL_SECONDS = 86400;

/**
 * 儲存使用者的 model 照,之後每一次試穿都用它,回傳它的儲存路徑。
 *
 * 路徑第一段是 userId,不是慣例而是條件:bucket policy 要求
 * `(storage.foldername(name))[1] = auth.uid()`,寫錯就上傳不了。所以 userId
 * 只能來自 session。
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

/** 拿一個能放進 `<img>` 的網址。bucket 不是公開的,所以必須簽。 */
export async function avatarUrl(path: string): Promise<string> {
  const { data, error } = await supabase.storage
    .from(AVATARS_BUCKET)
    .createSignedUrl(path, SIGNED_URL_TTL_SECONDS);
  if (error) throw error;
  return data.signedUrl;
}
