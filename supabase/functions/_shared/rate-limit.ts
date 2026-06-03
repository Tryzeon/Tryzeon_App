import { SupabaseClient } from "jsr:@supabase/supabase-js@2";

export async function checkRateLimit(
  adminClient: SupabaseClient,
  userId: string,
  bucket: string,
  limit: number,
  windowSeconds: number,
): Promise<boolean> {
  const { data, error } = await adminClient.rpc("check_rate_limit", {
    p_user_id: userId,
    p_bucket: bucket,
    p_limit: limit,
    p_window_seconds: windowSeconds,
  });
  if (error) {
    console.error("checkRateLimit error", error);
    return true;
  }
  return Boolean(data);
}
