import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { getAuthenticatedUserClient, getAdminClient } from "../_shared/supabase.ts";
import { QuotaManager, FeatureName } from "../_shared/quota.ts";
import { detectMimeType, mimeTypeToExtension, base64ToUint8Array } from "../_shared/image-utils.ts";
import { uploadTryonImageToR2 } from "../_shared/r2.ts";
import { generateTryonImage } from "./image.ts";
import { generateTryonVideo } from "./video.ts";
import { parseTryonRequest, ValidationError } from "./request.ts";
import { makeSourceResolver, resolveGarments } from "./garments.ts";
import { json, jsonError, rateLimitedResponse } from "../_shared/http.ts";

Deno.serve(async (req) => {
  let quotaManager: QuotaManager | undefined;

  try {
    const { userClient, user, errorResponse } = await getAuthenticatedUserClient(req);
    if (errorResponse) return errorResponse;

    const adminClient = getAdminClient();

    let tryonReq;
    try {
      const body = JSON.parse(await req.text());
      tryonReq = parseTryonRequest(body);
    } catch (err) {
      if (err instanceof ValidationError) {
        return jsonError(err.message, "VALIDATION_ERROR", 400);
      }
      return jsonError("Invalid JSON format", "BAD_REQUEST", 400);
    }

    const featureName: FeatureName = tryonReq.mode === "video" ? "tryon_video" : "tryon";
    quotaManager = new QuotaManager(adminClient, user!.id, featureName);

    const { allowed, usage } = await quotaManager.incrementQuota();
    if (!allowed) {
      return rateLimitedResponse(usage);
    }

    const resolver = makeSourceResolver(userClient!);
    const [avatarImage, garmentGroups] = await Promise.all([
      resolver(tryonReq.avatar),
      resolveGarments(tryonReq.garments, resolver),
    ]);

    const tryonImageBase64 = await generateTryonImage(
      avatarImage,
      garmentGroups,
      tryonReq.scenePrompt,
    );

    if (!tryonImageBase64) {
      return jsonError("Image generation failed", "AI_GENERATION_FAILED", 422);
    }

    if (tryonReq.mode === "video") {
      const videoUrl = await generateTryonVideo(tryonImageBase64, user!.id, tryonReq.transitionPrompt);
      return json({ videoUrl: videoUrl, usage: usage });
    }

    const cleanBase64 = tryonImageBase64.replace(/^data:image\/[a-z]+;base64,/, "");
    const mimeType = detectMimeType(cleanBase64);
    const extension = mimeTypeToExtension(mimeType);

    const bytes = base64ToUint8Array(cleanBase64);

    const timestamp = new Date().toISOString().replace(/[:.]/g, "-");
    const fileName = `${user!.id}/${timestamp}.${extension}`;

    const imageUrl = await uploadTryonImageToR2(bytes, fileName, mimeType);

    return json({ imageUrl: imageUrl, usage: usage });
  } catch (err) {
    console.error("Unexpected error:", err);

    await quotaManager?.rollbackQuota();

    return jsonError("Internal server error", "INTERNAL_ERROR", 500);
  }
});
