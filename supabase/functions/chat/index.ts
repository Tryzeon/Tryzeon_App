// Thin HTTP transport for the chat core: authenticate, then stream the core's
// progress + final answer as NDJSON. All chat logic (validation, quota,
// grounding, the tool loop, answer assembly) lives in _shared/chat so other
// platforms can reuse it without HTTP.
//
// Errors split by when they happen, not by what they are: a bad body is
// rejected with a status code, while anything raised after the 200 is committed
// arrives as an in-stream error frame. Both render from `classifyCoreError`.
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { getAdminClient, getAuthenticatedUserClient } from "../_shared/supabase.ts";
import { coreErrorResponse, jsonError } from "../_shared/http.ts";
import {
  classifyCoreError,
  runChatAgent,
  supabaseChatQuota,
} from "../_shared/chat/index.ts";
import { parseChatParams } from "./request.ts";
import { encodeEvent, errorEvent } from "./stream.ts";

Deno.serve(async (req) => {
  try {
    const { userClient, user, errorResponse } = await getAuthenticatedUserClient(req);
    if (errorResponse) return errorResponse;

    const params = parseChatParams(await req.text(), user!.id);
    // The turn runs on the requester's own client, so RLS bounds what its
    // grounding, searches and hydration can read. The service-role key goes no
    // further than the quota counter bound here.
    const quota = supabaseChatQuota(getAdminClient());

    const stream = new ReadableStream({
      async start(controller) {
        const send = (ev: Record<string, unknown>) => controller.enqueue(encodeEvent(ev));
        try {
          // `result.messages` is not sent: this client rebuilds the turn from
          // the events it already receives.
          const { blocks, usage } = await runChatAgent(
            userClient!,
            { ...params, onEvent: send },
            { quota },
          );
          send({
            type: "done",
            message: { role: "assistant", content: blocks },
            usage,
          });
        } catch (err) {
          send(errorEvent(err));
        } finally {
          controller.close();
        }
      },
    });

    return new Response(stream, {
      headers: {
        "Content-Type": "application/x-ndjson",
        "Cache-Control": "no-cache",
      },
    });
  } catch (err) {
    const info = classifyCoreError(err);
    if (info) return coreErrorResponse(info);
    console.error("Unexpected error:", err);
    return jsonError("Internal server error", "INTERNAL_ERROR", 500);
  }
});
