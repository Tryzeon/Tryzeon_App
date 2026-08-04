// supabase/functions/line-auth/index.ts
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { getAdminClient } from "../_shared/supabase.ts";
import { coreErrorResponse, json, jsonError } from "../_shared/http.ts";
import { classifyCoreError } from "../_shared/errors.ts";
import { makeCors } from "../_shared/cors.ts";
import { parseLineAuthBody } from "./request.ts";
import { LineAuthError, verifyLineIdToken } from "../_shared/line-identity.ts";
import { getOrCreateUserId } from "../_shared/line-user.ts";
import { mintSessionForUser } from "../_shared/auth-session.ts";

const cors = makeCors({ methods: "POST" });

Deno.serve(async (req) => {
  const guarded = cors.guard(req);
  if (guarded) return guarded;

  try {
    const channelId = Deno.env.get("LINE_CHANNEL_ID");
    if (!channelId) {
      return cors.wrap(jsonError("Server misconfigured", "INTERNAL_ERROR", 500));
    }

    const body = parseLineAuthBody(await req.text());
    const profile = await verifyLineIdToken(body.idToken, channelId, body.nonce);
    const admin = getAdminClient();

    // The order is load-bearing. `getOrCreateUserId` is what makes the session
    // land on the account the LIFF and the OA webhook already write to, and it
    // guarantees the user exists before a link is generated for it. Left to
    // itself, `generateLink` answers an unknown email by creating an account —
    // a path that is flaky (supabase/supabase#22521) and outside our control.
    // Do not reorder, and do not fold the two calls together.
    const userId = await getOrCreateUserId(admin, profile);
    const { refreshToken } = await mintSessionForUser(admin, userId);

    return cors.wrap(json({ refreshToken }));
  } catch (err) {
    if (err instanceof LineAuthError) {
      return cors.wrap(jsonError(err.message, "UNAUTHORIZED", 401));
    }
    const info = classifyCoreError(err);
    if (info) return cors.wrap(coreErrorResponse(info));
    console.error("line-auth unexpected error:", err);
    return cors.wrap(jsonError("Internal server error", "INTERNAL_ERROR", 500));
  }
});
