import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { getAdminClient, getAuthenticatedUserClient } from "../_shared/supabase.ts";
import { json, jsonError } from "../_shared/http.ts";
import { tryonErrorResponse } from "../_shared/tryon/http.ts";
import { runTryonJob } from "../_shared/tryon/index.ts";
import { parseTryonParams } from "./request.ts";

Deno.serve(async (req) => {
  try {
    const { userClient, user, errorResponse } = await getAuthenticatedUserClient(req);
    if (errorResponse) return errorResponse;

    // Every bad body — unparseable JSON included — raises a ValidationError, so
    // decoding needs no special case: it reaches tryonErrorResponse alongside
    // the core's own failures and yields one 400.
    const params = parseTryonParams(await req.text(), user!.id);

    // `materials` is the caller's own client, so RLS bounds which storage
    // objects a client-supplied path can reach.
    const result = await runTryonJob(
      { admin: getAdminClient(), materials: userClient! },
      params,
    );

    return result.kind === "video"
      ? json({ videoUrl: result.videoUrl, usage: result.usage })
      : json({ imageUrl: result.imageUrl, usage: result.usage });
  } catch (err) {
    const response = tryonErrorResponse(err);
    if (response) return response;
    console.error("Unexpected error:", err);
    return jsonError("Internal server error", "INTERNAL_ERROR", 500);
  }
});
