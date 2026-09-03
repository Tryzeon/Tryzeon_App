import { isAuthApiError } from "@supabase/supabase-js";
import { getIdToken } from "./liff";
import { supabase } from "./supabase";
import { toApiError } from "../api/errors";


/**
 * Only the server can say a session is usable: a stored one may point at a user
 * that has been deleted, or carry a revoked refresh token, while its access
 * token still looks fine until exp. A broken one has to be cleared on the spot
 * and replaced — keeping it just walks every later reload into the same wall.
 */
export async function ensureSession(): Promise<string> {
  return (await liveUserId()) ?? await mintSession();
}

async function liveUserId(): Promise<string | null> {
  const { data: { session } } = await supabase.auth.getSession();
  if (!session) return null;

  const { data, error } = await supabase.auth.getUser();
  if (!error && data.user) return data.user.id;

  // Not reaching the server does not mean the session is broken; clearing it
  // would throw away credentials that still work.
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
