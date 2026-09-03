/**
 * GoTrue has no admin "issue a session for this user id" API — `/token` only
 * offers the password, refresh_token, id_token, pkce and web3 grants — so the
 * one official route is to generate a magic link and redeem it immediately.
 */
import { createClient } from "@supabase/supabase-js";
import type { Database } from "./database.types.ts";
import { type DbClient, supabaseAnonKey, supabaseUrl } from "./supabase.ts";

export interface MintedSession {
  refreshToken: string;
}

/**
 * `implicit` is not optional: under PKCE the verify endpoint answers with an
 * auth code, and a link generated server-side has no code_verifier to redeem
 * one with.
 */
function defaultAnonClient(): DbClient {
  return createClient<Database>(supabaseUrl(), supabaseAnonKey(), {
    auth: { persistSession: false, autoRefreshToken: false, flowType: "implicit" },
  });
}

/**
 * The user MUST already exist. `generateLink` answers an unknown email by
 * turning the magiclink into a signup and creating one, which is both a flaky
 * path (supabase/supabase#22521) and, were the email ever to come from a
 * request, an unbounded account factory. Callers guarantee existence first.
 */
export async function mintSessionForUser(
  admin: DbClient,
  userId: string,
  anon: DbClient = defaultAnonClient(),
): Promise<MintedSession> {
  const { data: userData, error: userError } = await admin.auth.admin.getUserById(userId);
  const email = userData?.user?.email;
  if (userError || !email) {
    throw new Error(
      `user lookup failed for ${userId}: ${userError?.message ?? "no email on user"}`,
    );
  }

  const { data: link, error: linkError } = await admin.auth.admin.generateLink({
    type: "magiclink",
    email,
  });
  const hashedToken = link?.properties?.hashed_token;
  if (linkError || !hashedToken) {
    throw new Error(`generateLink failed: ${linkError?.message ?? "no hashed_token"}`);
  }

  const { data: verified, error: verifyError } = await anon.auth.verifyOtp({
    type: "magiclink",
    token_hash: hashedToken,
  });
  const refreshToken = verified?.session?.refresh_token;
  if (verifyError || !refreshToken) {
    throw new Error(`verifyOtp failed: ${verifyError?.message ?? "no session returned"}`);
  }

  return { refreshToken };
}
