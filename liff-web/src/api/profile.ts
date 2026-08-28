import { supabase } from "../lib/supabase";

/** 使用者存著的 model 照路徑,沒有就是 null。空字串一律當成沒有。 */
export async function fetchAvatarPath(userId: string): Promise<string | null> {
  const { data, error } = await supabase
    .from("user_profiles")
    .select("avatar_path")
    .eq("user_id", userId)
    .maybeSingle();
  if (error) throw error;

  const path = data?.avatar_path;
  return typeof path === "string" && path.length > 0 ? path : null;
}
