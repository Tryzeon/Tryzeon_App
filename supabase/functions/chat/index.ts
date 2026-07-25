// Thin HTTP transport for the chat agent: authenticate, then stream the core's
// progress + final answer as NDJSON. All agent logic (quota, grounding, the
// tool loop, answer assembly) lives in _shared/chat so other platforms can reuse
// it without HTTP. Rate-limit is delivered in-stream as an error event with code
// RATE_LIMIT_EXCEEDED (the run has already committed a 200 stream by then).
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { getAdminClient, getAuthenticatedUserClient } from "../_shared/supabase.ts";
import { jsonError } from "../_shared/http.ts";
import {
  type ChatMessage,
  QuotaExceededError,
  runChatAgent,
} from "../_shared/chat/index.ts";
import { encodeEvent } from "./stream.ts";

Deno.serve(async (req) => {
  try {
    // Auth: Verify JWT and get user securely
    const { user, errorResponse } = await getAuthenticatedUserClient(req);
    if (errorResponse) return errorResponse;

    const bodyText = await req.text();
    if (!bodyText) {
      return jsonError("Empty request body", "BAD_REQUEST", 400);
    }
    const { messages } = JSON.parse(bodyText);

    if (!Array.isArray(messages) || messages.length === 0) {
      return jsonError("Missing required fields", "VALIDATION_ERROR", 400);
    }

    const admin = getAdminClient();

    const stream = new ReadableStream({
      async start(controller) {
        const send = (ev: Record<string, unknown>) => controller.enqueue(encodeEvent(ev));
        try {
          const { blocks, usage } = await runChatAgent(
            { admin },
            { userId: user!.id, messages: messages as ChatMessage[], onEvent: send },
          );
          send({
            type: "done",
            message: { role: "assistant", content: blocks },
            usage,
          });
        } catch (err) {
          if (err instanceof QuotaExceededError) {
            send({ type: "error", code: "RATE_LIMIT_EXCEEDED", usage: err.usage });
          } else {
            console.error("Chat stream error:", err);
            send({ type: "error", code: "INTERNAL_ERROR" });
          }
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
    console.error("Unexpected error:", err);
    return jsonError("Internal server error", "INTERNAL_ERROR", 500);
  }
});
