import { supabase } from "../lib/supabase";

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
