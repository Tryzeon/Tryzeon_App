import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { getAdminClient } from "../_shared/supabase.ts";
import { json, jsonError } from "../_shared/http.ts";
import { LineAuthError, verifyLineIdToken } from "../_shared/line-identity.ts";
import { resolveSupabaseUser } from "../_shared/line-user.ts";
import {
  base64ToUint8Array,
  detectMimeType,
  mimeTypeToExtension,
} from "../_shared/image-utils.ts";
import { USER_AVATARS_BUCKET } from "../_shared/storage.ts";
import { avatarStoragePath } from "./path.ts";

const AVATAR_BUCKET = USER_AVATARS_BUCKET;

function corsHeaders(): Record<string, string> {
  const origin = Deno.env.get("LIFF_WEB_ORIGIN") ?? "*";
  return {
    "Access-Control-Allow-Origin": origin,
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, Authorization",
  };
}

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

    const body = JSON.parse(await req.text()) as Record<string, unknown>;
    const idToken = body.idToken;
    const avatarBase64 = body.avatarBase64;
    if (
      typeof idToken !== "string" || idToken.length === 0 ||
      typeof avatarBase64 !== "string" || avatarBase64.length === 0
    ) {
      return withCors(
        jsonError("idToken and avatarBase64 are required", "VALIDATION_ERROR", 400),
      );
    }

    const profile = await verifyLineIdToken(idToken, channelId);
    const admin = getAdminClient();
    const userId = await resolveSupabaseUser(admin, profile);

    const clean = avatarBase64.replace(/^data:image\/[a-z]+;base64,/, "");
    const mime = detectMimeType(clean);
    const ext = mimeTypeToExtension(mime);
    const path = avatarStoragePath(userId, Date.now(), ext);
    const bytes = base64ToUint8Array(clean);

    const { error: upErr } = await admin.storage
      .from(AVATAR_BUCKET)
      .upload(path, bytes, { contentType: mime, upsert: true });
    if (upErr) {
      throw new Error(`avatar upload failed: ${upErr.message}`);
    }

    const { error: updErr } = await admin
      .from("user_profiles")
      .update({ avatar_path: path })
      .eq("user_id", userId);
    if (updErr) {
      throw new Error(`avatar_path update failed: ${updErr.message}`);
    }

    return withCors(json({ ok: true, avatarPath: path }));
  } catch (err) {
    if (err instanceof LineAuthError) {
      return withCors(jsonError(err.message, "UNAUTHORIZED", 401));
    }
    console.error("liff-avatar unexpected error:", err);
    return withCors(jsonError("Internal server error", "INTERNAL_ERROR", 500));
  }
});
