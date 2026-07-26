import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { getAdminClient } from "../_shared/supabase.ts";
import { json, jsonError } from "../_shared/http.ts";
import { makeCors } from "../_shared/cors.ts";
import { LineAuthError, verifyLineIdToken } from "../_shared/line-identity.ts";
import { getOrCreateUserId } from "../_shared/line-user.ts";
import {
  base64ToUint8Array,
  detectMimeType,
  mimeTypeToExtension,
} from "../_shared/image-utils.ts";
import { USER_AVATARS_BUCKET } from "../_shared/storage.ts";
import { setAvatarPath } from "../_shared/user-profile.ts";
import { avatarStoragePath } from "./path.ts";

const cors = makeCors({ methods: "POST" });

Deno.serve(async (req) => {
  const guarded = cors.guard(req);
  if (guarded) return guarded;

  try {
    const channelId = Deno.env.get("LINE_CHANNEL_ID");
    if (!channelId) {
      return cors.wrap(jsonError("Server misconfigured", "INTERNAL_ERROR", 500));
    }

    const body = JSON.parse(await req.text()) as Record<string, unknown>;
    const idToken = body.idToken;
    const avatarBase64 = body.avatarBase64;
    if (
      typeof idToken !== "string" || idToken.length === 0 ||
      typeof avatarBase64 !== "string" || avatarBase64.length === 0
    ) {
      return cors.wrap(
        jsonError("idToken and avatarBase64 are required", "VALIDATION_ERROR", 400),
      );
    }

    const profile = await verifyLineIdToken(idToken, channelId);
    const admin = getAdminClient();
    const userId = await getOrCreateUserId(admin, profile);

    const clean = avatarBase64.replace(/^data:image\/[a-z]+;base64,/, "");
    const mime = detectMimeType(clean);
    const ext = mimeTypeToExtension(mime);
    const path = avatarStoragePath(userId, Date.now(), ext);
    const bytes = base64ToUint8Array(clean);

    const { error: upErr } = await admin.storage
      .from(USER_AVATARS_BUCKET)
      .upload(path, bytes, { contentType: mime, upsert: true });
    if (upErr) {
      throw new Error(`avatar upload failed: ${upErr.message}`);
    }

    await setAvatarPath(admin, userId, path);

    return cors.wrap(json({ ok: true, avatarPath: path }));
  } catch (err) {
    if (err instanceof LineAuthError) {
      return cors.wrap(jsonError(err.message, "UNAUTHORIZED", 401));
    }
    console.error("liff-avatar unexpected error:", err);
    return cors.wrap(jsonError("Internal server error", "INTERNAL_ERROR", 500));
  }
});
