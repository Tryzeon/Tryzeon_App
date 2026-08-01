// supabase/functions/liff-tryon/index.ts
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { getAdminClient } from "../_shared/supabase.ts";
import { json, jsonError } from "../_shared/http.ts";
import { makeCors } from "../_shared/cors.ts";
import { parseLiffTryonBody } from "./request.ts";
import { LineAuthError, verifyLineIdToken } from "../_shared/line-identity.ts";
import { getOrCreateUserId } from "../_shared/line-user.ts";
import { tryonErrorResponse } from "../_shared/tryon/http.ts";
import { runTryonJob } from "../_shared/tryon/index.ts";

const cors = makeCors({ methods: "POST" });

Deno.serve(async (req) => {
  const guarded = cors.guard(req);
  if (guarded) return guarded;

  try {
    const channelId = Deno.env.get("LINE_CHANNEL_ID");
    if (!channelId) {
      return cors.wrap(jsonError("Server misconfigured", "INTERNAL_ERROR", 500));
    }

    const body = parseLiffTryonBody(await req.text());
    const profile = await verifyLineIdToken(body.idToken, channelId);
    const admin = getAdminClient();
    const userId = await getOrCreateUserId(admin, profile);

    const result = await runTryonJob({ admin, materials: admin }, {
      userId,
      garments: [{ productId: body.productId }],
      mode: "image",
    });
    return cors.wrap(json({ imageUrl: result.imageUrl, usage: result.usage }));
  } catch (err) {
    if (err instanceof LineAuthError) {
      return cors.wrap(jsonError(err.message, "UNAUTHORIZED", 401));
    }
    const response = tryonErrorResponse(err);
    if (response) return cors.wrap(response);
    console.error("liff-tryon unexpected error:", err);
    return cors.wrap(jsonError("Internal server error", "INTERNAL_ERROR", 500));
  }
});
