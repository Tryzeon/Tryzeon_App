import "@supabase/functions-js/edge-runtime.d.ts";
import { getAuthenticatedUserClient } from "../_shared/supabase.ts";
import {
  analyzeImage,
  checkImageAnalysisRateLimit,
  validateBase64,
} from "../_shared/image-analysis.ts";
import { json, jsonError } from "../_shared/http.ts";
import { ANALYSIS_PROMPT, ANALYSIS_SCHEMA, toResponse } from "./analysis.ts";

Deno.serve(async (req) => {
  try {
    const { user, errorResponse } = await getAuthenticatedUserClient(req);
    if (errorResponse) return errorResponse;

    const body = await req.json().catch(() => null);

    const validation = validateBase64(body?.base64);
    if (!validation.ok) return validation.response;
    const base64 = validation.value;

    const limited = await checkImageAnalysisRateLimit(user!.id, "wardrobe_image_analysis");
    if (limited) return limited;

    const parsed = await analyzeImage({
      base64,
      prompt: ANALYSIS_PROMPT,
      schema: ANALYSIS_SCHEMA,
    });

    return json(toResponse(parsed));
  } catch (err) {
    console.error("analyze-wardrobe-image error", err);
    return jsonError("Internal error", "INTERNAL", 500);
  }
});
