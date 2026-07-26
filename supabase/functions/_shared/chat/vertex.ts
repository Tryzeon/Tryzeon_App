/**
 * Vertex AI implementation of the core's `AgentRunner` port. This module owns
 * everything SDK-specific — the provider, the tool set, the stream, the
 * structured-output call — and the core sees only "run a turn, get an answer
 * and the rounds it took".
 *
 * It also owns the transcript rule: a tool call is an assistant turn, its
 * result a user turn. That rule belongs wherever the loop is observed, because
 * only here is the pairing still known; every consumer downstream gets messages
 * that are already correct.
 */
import { Output, stepCountIs, streamText } from "npm:ai@^6.0.208";
import { createVertex } from "npm:@ai-sdk/google-vertex@^4.0.147/edge";
import { chatModel, vertexApiKey } from "../vertex/config.ts";
import { toModelMessages } from "./logic.ts";
import { answerSchema, buildTools } from "./tools.ts";
import type {
  AgentRunner,
  ChatEvent,
  ChatMessage,
  ChatRole,
} from "./types.ts";

// Tool calls one turn may make before the loop is stopped. This runner's own
// budget, not a caller-facing limit: a substituted `AgentRunner` sets its own.
const MAX_AGENT_STEPS = 10;

/**
 * The provider, built on first use and kept for the isolate.
 *
 * Deliberately not built at import: `run.ts` names this runner as its default,
 * so anything that touches the chat core pulls this module in — including
 * callers that always pass their own runner, and tests that never reach the
 * network. Building it at import would make a Vertex API key a requirement for
 * all of them.
 *
 * Express mode: the API key alone authenticates, and it is the same key try-on
 * and the analysis helpers use — neither project nor location is needed.
 */
let provider: ReturnType<typeof createVertex> | null = null;
const vertexProvider = () =>
  provider ??= createVertex({ apiKey: vertexApiKey() });

export const runVertexAgent: AgentRunner = async (req) => {
  const tools = buildTools({
    admin: req.admin,
    userId: req.userId,
    categoryIdByName: req.context.categoryIdByName,
  });

  // The SDK runs the loop: search_* tools have `execute`, so it calls them and
  // re-prompts automatically (capped by stopWhen). The final answer is produced
  // as structured `output`, not as a tool call.
  const result = streamText({
    model: vertexProvider()(chatModel()),
    system: req.context.systemInstruction,
    messages: toModelMessages(req.messages),
    tools,
    output: Output.object({ schema: answerSchema }),
    stopWhen: stepCountIs(MAX_AGENT_STEPS),
  });

  const rounds: ChatMessage[] = [];

  // A progress event and the block it records are the same value, emitted once.
  // That identity is the contract a streaming client relies on to rebuild the
  // transcript from what it watched, so it is stated here rather than left to
  // two literals staying in step.
  const record = (role: ChatRole, block: ChatEvent) => {
    rounds.push({ role, content: [block] });
    req.onEvent?.(block);
  };

  for await (const part of result.fullStream) {
    if (part.type === "tool-call") {
      record("assistant", {
        type: "tool_use",
        id: part.toolCallId,
        name: part.toolName,
        input: part.input,
      });
    } else if (part.type === "tool-result") {
      record("user", {
        type: "tool_result",
        tool_use_id: part.toolCallId,
        content: part.output,
      });
    }
  }

  // `result.output` rejects when the model produced nothing matching the
  // schema. That is an answer we could not read, not a fault: the turn ran and
  // the core degrades to fallback text, so it is reported as a null output
  // rather than raised.
  try {
    return { output: await result.output as Record<string, any>, rounds };
  } catch (err) {
    console.error("Structured output unavailable:", err);
    return { output: null, rounds };
  }
};
