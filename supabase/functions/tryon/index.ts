import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { getAdminClient, getAuthenticatedUserClient } from "../_shared/supabase.ts";
import { json, jsonError } from "../_shared/http.ts";
import { makeCors } from "../_shared/cors.ts";
import { tryonErrorResponse } from "../_shared/tryon/http.ts";
import { runTryonJob, supabaseQuota } from "../_shared/tryon/index.ts";
import { parseTryonParams } from "./request.ts";

// Two clients call this now: the Flutter app, which needs no CORS, and the
// LIFF web app, which does.
const cors = makeCors({ methods: "POST" });

Deno.serve(async (req) => {
  const guarded = cors.guard(req);
  if (guarded) return guarded;

  try {
    const { userClient, user, errorResponse } = await getAuthenticatedUserClient(req);
    if (errorResponse) return cors.wrap(errorResponse);

    // Every bad body — unparseable JSON included — raises a ValidationError, so
    // decoding needs no special case: it reaches tryonErrorResponse alongside
    // the core's own failures and yields one 400.
    const params = parseTryonParams(await req.text(), user!.id);

    // The job runs on the requester's own client, so RLS bounds every row and
    // storage object it can reach. The service-role key goes no further than the
    // quota counter bound here.
    const result = await runTryonJob(userClient!, params, {
      quota: supabaseQuota(getAdminClient()),
    });

    return cors.wrap(
      result.kind === "video"
        ? json({ videoUrl: result.videoUrl, usage: result.usage })
        : json({ imageUrl: result.imageUrl, usage: result.usage }),
    );
  } catch (err) {
    const response = tryonErrorResponse(err);
    if (response) return cors.wrap(response);
    console.error("Unexpected error:", err);
    return cors.wrap(jsonError("Internal server error", "INTERNAL_ERROR", 500));
  }
});
