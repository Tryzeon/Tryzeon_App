// supabase/functions/parse-size-voice/index.ts
import { getAuthenticatedUserClient } from "../_shared/supabase.ts";
import { checkImageAnalysisRateLimit } from "../_shared/image-analysis.ts";
import { json, jsonError } from "../_shared/http.ts";
import { analyzeAudio } from "../_shared/audio-analysis.ts";
import { buildPrompt, buildSchema, normalizeParsedSizes, validateAudio } from "./parse.ts";

Deno.serve(async (req) => {
  try {
    const { user, errorResponse } = await getAuthenticatedUserClient(req);
    if (errorResponse) return errorResponse;

    const body = await req.json().catch(() => null);
    const validation = validateAudio(body?.audioBase64, body?.mimeType);
    if (!validation.ok) return validation.response;

    const limited = await checkImageAnalysisRateLimit(user!.id, "size_voice_parse");
    if (limited) return limited;

    const raw = await analyzeAudio({
      audioBase64: validation.base64,
      mimeType: validation.mimeType,
      prompt: buildPrompt(),
      schema: buildSchema(),
    });

    return json({ sizes: normalizeParsedSizes(raw) });
  } catch (err) {
    console.error("parse-size-voice error", err);
    return jsonError("Internal error", "INTERNAL", 500);
  }
});
