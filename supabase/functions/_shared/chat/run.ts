// Chat agent core. Platform-agnostic: given a userId + prior messages it runs
// the tool-using agent loop and returns ordered answer blocks. Quota (with
// rollback) is owned here — mirrors _shared/tryon/run.ts — so every caller
// (the chat edge, a LINE adapter, …) gets the same accounting for free.
// default model: gemini-2.5-flash
import { streamText, stepCountIs, Output } from "npm:ai@^6.0.208";
import { createVertex } from "npm:@ai-sdk/google-vertex@^4.0.147/edge";
import { QuotaExceededError, QuotaManager } from "../quota.ts";
import { buildChatContext } from "./context.ts";
import { answerSchema, buildTools } from "./tools.ts";
import {
  assembleAnswerBlocks,
  type ContentBlock,
  parseAnswerRefs,
  PRODUCT_SELECT,
  toModelMessages,
  WARDROBE_SELECT,
} from "./logic.ts";
import type {
  ChatResult,
  RunChatAgentDeps,
  RunChatAgentParams,
} from "./types.ts";

const FALLBACK_TEXT = "抱歉，我這次沒能幫你找到，可以再多說一點你的需求嗎？";
const CHAT_MODEL = Deno.env.get("CHAT_MODEL") ?? "gemini-2.5-flash";

// Vertex provider, authenticated with the service account. The edge variant signs
// the SA JWT via Web Crypto. We pass credentials explicitly so we can un-escape
// the private key: the provider strips whitespace but not literal "\n", and keys
// copied from the JSON key file carry escaped newlines that otherwise break atob.
const vertex = createVertex({
  project: Deno.env.get("GOOGLE_VERTEX_PROJECT"),
  location: Deno.env.get("GOOGLE_VERTEX_LOCATION") ?? "us-central1",
  googleCredentials: {
    clientEmail: Deno.env.get("GOOGLE_CLIENT_EMAIL") ?? "",
    privateKey: (Deno.env.get("GOOGLE_PRIVATE_KEY") ?? "").replace(/\\n/g, "\n"),
    privateKeyId: Deno.env.get("GOOGLE_PRIVATE_KEY_ID"),
  },
});

// Fetch the rows the model referenced in its answer output, keyed by id, by running the
// caller's prepared query with an `.in("id", ids)` filter. Empty ids → empty map
// (no query); missing ids (e.g. a since-deleted item) are simply absent.
async function fetchRowsByIds(
  // deno-lint-ignore no-explicit-any
  query: any,
  ids: string[],
): Promise<Map<string, Record<string, any>>> {
  const map = new Map<string, Record<string, any>>();
  if (ids.length === 0) return map;
  const { data, error } = await query.in("id", ids);
  if (error) throw error;
  for (const row of data ?? []) map.set(String(row.id), row);
  return map;
}

/**
 * Single chat-agent entry point: quota -> ground -> agent loop -> assemble.
 *
 * The AI SDK runs the loop: search_* tools have `execute` so it calls them and
 * re-prompts automatically (capped by stopWhen). The final answer is produced as
 * structured `output` (answerSchema), not a tool call. tool_use/tool_result
 * events are surfaced live via `params.onEvent`; the ordered answer blocks are
 * returned. Quota is charged up front and rolled back if the agent loop throws;
 * an unusable structured output degrades to a fallback text block (quota stays
 * spent — the model did run). Throws {@link QuotaExceededError} when over quota.
 */
export async function runChatAgent(
  deps: RunChatAgentDeps,
  params: RunChatAgentParams,
): Promise<ChatResult> {
  const { admin } = deps;
  const { userId, messages, onEvent } = params;

  const quota = new QuotaManager(admin, userId, "chat");
  const { allowed, usage } = await quota.incrementQuota();
  if (!allowed) {
    throw new QuotaExceededError(usage);
  }

  try {
    const { systemInstruction, categoryIdByName } = await buildChatContext(admin, userId);
    const tools = buildTools({ adminClient: admin, userId, categoryIdByName });

    const result = streamText({
      model: vertex(CHAT_MODEL),
      system: systemInstruction,
      messages: toModelMessages(messages),
      tools,
      output: Output.object({ schema: answerSchema }),
      stopWhen: stepCountIs(10),
    });

    for await (const part of result.fullStream) {
      if (part.type === "tool-call") {
        onEvent?.({ type: "tool_use", id: part.toolCallId, name: part.toolName, input: part.input });
      } else if (part.type === "tool-result") {
        onEvent?.({ type: "tool_result", tool_use_id: part.toolCallId, content: part.output });
      }
    }

    let blocks: ContentBlock[];
    try {
      const output = (await result.output) as Record<string, any>;
      const refs = parseAnswerRefs(output);
      const [products, wardrobe] = await Promise.all([
        fetchRowsByIds(
          admin.from("products").select(PRODUCT_SELECT),
          refs.filter((r) => r.type === "product").map((r) => r.id),
        ),
        fetchRowsByIds(
          admin.from("wardrobe_items").select(WARDROBE_SELECT).eq("user_id", userId),
          refs.filter((r) => r.type === "wardrobe").map((r) => r.id),
        ),
      ]);
      blocks = assembleAnswerBlocks(refs, products, wardrobe);
    } catch (outErr) {
      console.error("Structured output unavailable:", outErr);
      blocks = [];
    }
    if (blocks.length === 0) {
      blocks = [{ type: "text", text: FALLBACK_TEXT }];
    }

    return { blocks, usage };
  } catch (err) {
    await quota.rollbackQuota();
    throw err;
  }
}
