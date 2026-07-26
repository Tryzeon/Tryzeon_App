import { QuotaExceededError } from "../quota.ts";
import { buildChatContext } from "./context.ts";
import { supabaseAnswerRows } from "./hydrate.ts";
import { assembleAnswerBlocks, parseAnswerRefs } from "./logic.ts";
import { supabaseChatQuota } from "./quota.ts";
import { validateChatParams } from "./validate.ts";
import { runVertexAgent } from "./vertex.ts";
import type {
  AgentRunner,
  AnswerHydrator,
  ChatClients,
  ChatMessage,
  ChatParams,
  ChatQuotaFactory,
  ChatResult,
  ContentBlock,
  ContextLoader,
} from "./types.ts";

const FALLBACK_TEXT = "抱歉，我這次沒能幫你找到，可以再多說一點你的需求嗎？";

export interface RunChatAgentDeps {
  loadContext?: ContextLoader;
  runAgent?: AgentRunner;
  hydrate?: AnswerHydrator;
  quota?: ChatQuotaFactory;
}

/**
 * Single chat entry point: validate -> quota -> ground -> agent loop ->
 * hydrate -> assemble.
 *
 * Platform-agnostic: given a userId and the prior conversation it returns the
 * ordered answer blocks plus the turns to append, so every caller (the chat
 * edge, a LINE adapter, …) gets the same accounting, the same grounding and the
 * same transcript rules for free.
 *
 * Quota is charged up front and refunded if anything after it throws. An
 * unusable structured output is not a throw — the model ran, so quota stays
 * spent and the answer degrades to a single fallback text block. A failure to
 * read the referenced rows is a throw: that is a server fault, and reporting it
 * as "I couldn't find anything" would charge the caller for a lie.
 */
export async function runChatAgent(
  clients: ChatClients,
  params: ChatParams,
  deps: RunChatAgentDeps = {},
): Promise<ChatResult> {
  // Everything below runs on `turn`, never on the raw `params`: the guard is
  // also the normalizer, so the run cannot read a message the guard did not see.
  const turn = validateChatParams(params);

  const loadContext = deps.loadContext ?? buildChatContext;
  const runAgent = deps.runAgent ?? runVertexAgent;
  const hydrate = deps.hydrate ?? supabaseAnswerRows;
  const openQuota = deps.quota ?? supabaseChatQuota;

  const { admin } = clients;
  const quota = openQuota(admin, turn.userId);
  const { allowed, usage } = await quota.charge();
  if (!allowed) {
    throw new QuotaExceededError(usage);
  }

  try {
    const context = await loadContext(admin, turn.userId);

    const { output, rounds } = await runAgent({
      admin,
      userId: turn.userId,
      context,
      messages: turn.messages,
      onEvent: turn.onEvent,
    });

    let blocks: ContentBlock[] = [];
    if (output) {
      const refs = parseAnswerRefs(output);
      blocks = assembleAnswerBlocks(refs, await hydrate(admin, turn.userId, refs));
    }
    if (blocks.length === 0) {
      blocks = [{ type: "text", text: FALLBACK_TEXT }];
    }

    const answer: ChatMessage = { role: "assistant", content: blocks };
    return { blocks, messages: [...rounds, answer], usage };
  } catch (err) {
    // Refund is best-effort: a failure here must not replace the error that
    // actually caused the turn to fail, or callers would report the wrong thing.
    try {
      await quota.refund();
    } catch (refundErr) {
      console.error("chat quota refund failed:", refundErr);
    }
    throw err;
  }
}
