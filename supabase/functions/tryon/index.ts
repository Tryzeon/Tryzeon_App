import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { getAdminClient, getAuthenticatedUserClient } from "../_shared/supabase.ts";
import { json, jsonError, rateLimitedResponse } from "../_shared/http.ts";
import {
  GenerationFailedError,
  parseTryonParams,
  QuotaExceededError,
  runTryonJob,
  ValidationError,
} from "../_shared/tryon/index.ts";

Deno.serve(async (req) => {
  try {
    const { userClient, user, errorResponse } = await getAuthenticatedUserClient(req);
    if (errorResponse) return errorResponse;

    const admin = getAdminClient();

    let params;
    try {
      params = parseTryonParams(JSON.parse(await req.text()), user!.id);
    } catch (err) {
      if (err instanceof ValidationError) {
        return jsonError(err.message, "VALIDATION_ERROR", 400);
      }
      return jsonError("Invalid JSON format", "BAD_REQUEST", 400);
    }

    const result = await runTryonJob({ admin, materials: userClient! }, params);

    return result.kind === "video"
      ? json({ videoUrl: result.videoUrl, usage: result.usage })
      : json({ imageUrl: result.imageUrl, usage: result.usage });
  } catch (err) {
    if (err instanceof QuotaExceededError) {
      return rateLimitedResponse(err.usage);
    }
    if (err instanceof GenerationFailedError) {
      return jsonError("Image generation failed", "AI_GENERATION_FAILED", 422);
    }
    console.error("Unexpected error:", err);
    return jsonError("Internal server error", "INTERNAL_ERROR", 500);
  }
});
