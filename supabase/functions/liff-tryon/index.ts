// supabase/functions/liff-tryon/index.ts
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { getAdminClient } from "../_shared/supabase.ts";
import { json, jsonError } from "../_shared/http.ts";
import { corsHeaders, parseLiffTryonBody, ValidationError } from "./request.ts";
import { resolveProductGarmentKey } from "./catalog.ts";
import { LineAuthError, verifyLineIdToken } from "../_shared/line-identity.ts";
import { resolveSupabaseUser } from "../_shared/line-user.ts";
import {
  GenerationFailedError,
  QuotaExceededError,
  runTryonJob,
} from "../_shared/tryon/index.ts";

function withCors(resp: Response): Response {
  const headers = new Headers(resp.headers);
  for (const [k, v] of Object.entries(corsHeaders())) headers.set(k, v);
  return new Response(resp.body, { status: resp.status, headers });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders() });
  }
  if (req.method !== "POST") {
    return withCors(jsonError("Method not allowed", "METHOD_NOT_ALLOWED", 405));
  }

  try {
    const channelId = Deno.env.get("LINE_CHANNEL_ID");
    if (!channelId) {
      return withCors(jsonError("Server misconfigured", "INTERNAL_ERROR", 500));
    }

    const body = parseLiffTryonBody(JSON.parse(await req.text()));
    const profile = await verifyLineIdToken(body.idToken, channelId);
    const admin = getAdminClient();
    const userId = await resolveSupabaseUser(admin, profile);
    const garmentKey = await resolveProductGarmentKey(admin, body.productId);
    const result = await runTryonJob({ admin }, {
      userId,
      avatar: { base64: body.avatarBase64 },
      garments: [{ images: [{ path: garmentKey }] }],
      mode: "image",
    });
    if (result.kind !== "image") {
      throw new Error("expected image result for liff-tryon");
    }
    return withCors(json({ imageUrl: result.imageUrl, usage: result.usage }));
  } catch (err) {
    if (err instanceof ValidationError) {
      return withCors(jsonError(err.message, "VALIDATION_ERROR", 400));
    }
    if (err instanceof LineAuthError) {
      return withCors(jsonError(err.message, "UNAUTHORIZED", 401));
    }
    if (err instanceof QuotaExceededError) {
      return withCors(
        json({ error: "Rate limit exceeded", code: "RATE_LIMIT_EXCEEDED", usage: err.usage }, 429),
      );
    }
    if (err instanceof GenerationFailedError) {
      return withCors(jsonError("Image generation failed", "AI_GENERATION_FAILED", 422));
    }
    console.error("liff-tryon unexpected error:", err);
    return withCors(jsonError("Internal server error", "INTERNAL_ERROR", 500));
  }
});
