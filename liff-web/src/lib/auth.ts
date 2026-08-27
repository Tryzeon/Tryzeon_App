import { getIdToken } from "./liff";
import { supabase } from "./supabase";
import { toApiError } from "../api/errors";


export async function ensureSession(): Promise<void> {
  const { data: { session } } = await supabase.auth.getSession();
  if (session) return;

  const { data, error } = await supabase.functions.invoke("line-auth", {
    body: { idToken: getIdToken() },
  });
  if (error) throw toApiError(error);

  const refreshToken = (data as { refreshToken?: string } | null)?.refreshToken;
  if (!refreshToken) throw new Error("line-auth returned no refreshToken");

  const { error: refreshError } = await supabase.auth.refreshSession({
    refresh_token: refreshToken,
  });
  if (refreshError) throw refreshError;
}

export async function currentUserId(): Promise<string> {
  const { data: { user }, error } = await supabase.auth.getUser();
  if (error) throw error;
  if (!user) throw new Error("no supabase session");
  return user.id;
}
