import { isAuthApiError } from "@supabase/supabase-js";
import { getIdToken } from "./liff";
import { supabase } from "./supabase";
import { toApiError } from "../api/errors";


/**
 * 「能用」只有伺服器說了算:存著的 session 可能指向一個已經被刪掉的 user,或帶
 * 著已失效的 refresh token,而它的 access token 在 exp 之前看起來都還是好的。壞
 * 掉的那份要當場清掉再換新的 —— 留著只會讓之後每次重新載入都撞同一面牆。
 */
export async function ensureSession(): Promise<string> {
  return (await liveUserId()) ?? await mintSession();
}

async function liveUserId(): Promise<string | null> {
  const { data: { session } } = await supabase.auth.getSession();
  if (!session) return null;

  const { data, error } = await supabase.auth.getUser();
  if (!error && data.user) return data.user.id;

  // 連不上伺服器不算「session 壞了」,清掉會把還能用的憑證一起丟掉。
  if (!isAuthApiError(error)) throw error ?? new Error("no user on session");

  await supabase.auth.signOut({ scope: "local" });
  return null;
}

async function mintSession(): Promise<string> {
  const { data, error } = await supabase.functions.invoke("line-auth", {
    body: { idToken: getIdToken() },
  });
  if (error) throw toApiError(error);

  const refreshToken = (data as { refreshToken?: string } | null)?.refreshToken;
  if (!refreshToken) throw new Error("line-auth returned no refreshToken");

  const { data: refreshed, error: refreshError } = await supabase.auth.refreshSession({
    refresh_token: refreshToken,
  });
  if (refreshError) throw refreshError;

  const userId = refreshed.user?.id;
  if (!userId) throw new Error("refreshSession returned no user");
  return userId;
}

export async function currentUserId(): Promise<string> {
  const { data: { user }, error } = await supabase.auth.getUser();
  if (error) throw error;
  if (!user) throw new Error("no supabase session");
  return user.id;
}
