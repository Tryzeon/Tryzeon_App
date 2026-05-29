import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { getAuthenticatedUserClient, getAdminClient } from "../_shared/supabase.ts";
import { QuotaManager, FeatureName } from "../_shared/quota.ts";
import { detectMimeType, mimeTypeToExtension, base64ToUint8Array } from "../_shared/image-utils.ts";
import { uploadTryonImageToR2 } from "../_shared/r2.ts";
import { generateTryonImage } from "./image.ts";
import { generateTryonVideo } from "./video.ts";
import { parseTryonRequest, ValidationError } from "./request.ts";
import { makeSourceResolver, resolveGarments } from "./garments.ts";

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
        return new Response(
          JSON.stringify({ error: err.message, code: "VALIDATION_ERROR" }),
          { status: 400, headers: { "Content-Type": "application/json" } },
        );
      }
      return new Response(
        JSON.stringify({ error: "Invalid JSON format", code: "BAD_REQUEST" }),
        { status: 400, headers: { "Content-Type": "application/json" } },
      );
    }

    const featureName: FeatureName = tryonReq.mode === "video" ? "tryon_video" : "tryon";
    quotaManager = new QuotaManager(adminClient, user!.id, featureName);

    const { allowed, usage } = await quotaManager.incrementQuota();
    if (!allowed) {
      return new Response(
        JSON.stringify({ error: "Rate limit exceeded", code: "RATE_LIMIT_EXCEEDED", usage }),
        { status: 429, headers: { "Content-Type": "application/json" } },
      );
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
      return new Response(
        JSON.stringify({ error: "Image generation failed", code: "AI_GENERATION_FAILED" }),
        { status: 422, headers: { "Content-Type": "application/json" } },
      );
    }

    if (tryonReq.mode === "video") {
      const videoUrl = await generateTryonVideo(tryonImageBase64, user!.id, tryonReq.transitionPrompt);
      return new Response(
        JSON.stringify({ videoUrl: videoUrl, usage: usage }),
        { headers: { "Content-Type": "application/json" } },
      );
    }

    const cleanBase64 = tryonImageBase64.replace(/^data:image\/[a-z]+;base64,/, "");
    const mimeType = detectMimeType(cleanBase64);
    const extension = mimeTypeToExtension(mimeType);

    const bytes = base64ToUint8Array(cleanBase64);
    const imageBuffer = bytes.buffer;

    const timestamp = new Date().toISOString().replace(/[:.]/g, "-");
    const fileName = `${user!.id}/${timestamp}.${extension}`;

    const imageUrl = await uploadTryonImageToR2(imageBuffer, fileName, mimeType);

    return new Response(
      JSON.stringify({ imageUrl: imageUrl, usage: usage }),
      { headers: { "Content-Type": "application/json" } },
    );
  } catch (err) {
    console.error("Unexpected error:", err);

    await quotaManager?.rollbackQuota();

    return new Response(
      JSON.stringify({ error: "Internal server error", code: "INTERNAL_ERROR" }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }
});
