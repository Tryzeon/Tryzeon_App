/**
 * Opening a GoTrue session for an auth user that already exists.
 *
 * GoTrue has no admin "issue a session for this user id" API — `/token` only
 * offers the password, refresh_token, id_token, pkce and web3 grants — so the
 * one official route is to generate a magic link and redeem it immediately.
 *
 * The parameter is a user id, never an email, even though the link is
 * email-keyed. Which email a user carries is the business of whoever minted
 * them (`line-user.ts` derives one from the LINE sub), and reading it back here
 * keeps that format from acquiring a second knower.
 */
import { createClient, SupabaseClient } from "jsr:@supabase/supabase-js@2";
import { CONFIG } from "./supabase.ts";

/** A GoTrue session, reduced to the one credential a client needs to adopt it. */
export interface MintedSession {
  refreshToken: string;
}

/**
 * `implicit` is not optional: under PKCE the verify endpoint answers with an
 * auth code, and a link generated server-side has no code_verifier to redeem
 * one with.
 */
function defaultAnonClient(): SupabaseClient {
  return createClient(CONFIG.SUPABASE_URL, CONFIG.SUPABASE_ANON_KEY, {
    auth: { persistSession: false, autoRefreshToken: false, flowType: "implicit" },
  });
}

/**
 * The user MUST already exist. `generateLink` answers an unknown email by
 * turning the magiclink into a signup and creating one, which is both a flaky
 * path (supabase/supabase#22521) and, were the email ever to come from a
 * request, an unbounded account factory. Callers guarantee existence first.
 *
 * `anon` is injectable for testing, following `verifyLineIdToken`'s `fetchFn`.
 */
export async function mintSessionForUser(
  admin: SupabaseClient,
  userId: string,
  anon: SupabaseClient = defaultAnonClient(),
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
