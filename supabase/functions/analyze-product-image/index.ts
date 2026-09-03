import "jsr:@supabase/functions-js@^2.113.0/edge-runtime.d.ts";
import { getAuthenticatedUserClient } from "../_shared/supabase.ts";
import {
  analyzeImage,
  checkImageAnalysisRateLimit,
  validateBase64,
} from "../_shared/image-analysis.ts";
import { json, jsonError } from "../_shared/http.ts";
import { buildPrompt, buildSchema, toResponse } from "./analysis.ts";

Deno.serve(async (req) => {
  try {
    const { userClient, user, errorResponse } = await getAuthenticatedUserClient(req);
    if (errorResponse) return errorResponse;

    const body = await req.json().catch(() => null);
    const validation = validateBase64(body?.base64);
    if (!validation.ok) return validation.response;
    const base64 = validation.value;

    const limited = await checkImageAnalysisRateLimit(user!.id, "product_image_analysis");
    if (limited) return limited;

    // The caller's own client: `product_categories` is world-readable, so this
    // read needs no privilege the caller does not already have.
    const { data: categories, error: categoriesError } = await userClient!
      .from("product_categories")
      .select("id, name");
    if (categoriesError) {
      console.warn("analyze-product-image: failed to load product_categories", categoriesError);
    }
    const idByName = new Map<string, string>(
      (categories ?? []).map((c) => [c.name, c.id]),
    );
    const categoryNames = [...idByName.keys()];

    const parsed = await analyzeImage({
      base64,
      prompt: buildPrompt(categoryNames),
      schema: buildSchema(categoryNames),
    });

    return json(toResponse(parsed, idByName));
  } catch (err) {
    console.error("analyze-product-image error", err);
    return jsonError("Internal error", "INTERNAL", 500);
  }
});
