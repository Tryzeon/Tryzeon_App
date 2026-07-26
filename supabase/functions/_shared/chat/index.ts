/**
 * Public surface of the chat core.
 *
 * The core spans "a conversation -> the next turn": validation, quota,
 * grounding, the tool-using agent loop, and hydrating the rows the model
 * referenced. It is transport-agnostic — nothing reachable from here knows
 * about HTTP, NDJSON, LINE, or any wire format. Adapters own who the caller is,
 * where the conversation is stored, and how the answer is rendered.
 *
 * What belongs here is what a caller needs in order to run a turn, describe its
 * inputs and outputs, and classify its failures — nothing more. The pieces the
 * core wires up for itself (`validateChatParams`, `buildChatContext`,
 * `buildTools`, `runVertexAgent`, `supabaseAnswerRows`, `supabaseChatQuota`,
 * `toModelMessages`) are reachable by their own modules, and are left out so
 * that "public surface" stays a claim about this file rather than a description
 * of the folder.
 *
 * Failures are not ours to publish either. A chat turn raises nothing of its
 * own — a rejected input and a spent quota are every core's — so the taxonomy
 * lives in `_shared/errors.ts` and its HTTP rendering in `_shared/http.ts`,
 * both re-exported below rather than restated as a chat-shaped copy.
 */

// Running a turn. The ports come along because `RunChatAgentDeps` is part of
// `runChatAgent`'s signature and its members would otherwise be unnameable.
export { runChatAgent, type RunChatAgentDeps } from "./run.ts";
export type {
  AgentAnswer,
  AgentRequest,
  AgentRunner,
  AnswerHydrator,
  AnswerRows,
  ChatQuotaFactory,
  ContextLoader,
  QuotaPort,
} from "./types.ts";

// Describing a turn and reading its result.
export { LIMITS } from "./types.ts";
export type {
  AnswerRef,
  ChatClients,
  ChatContext,
  ChatEvent,
  ChatMessage,
  ChatParams,
  ChatResult,
  ChatRole,
  ContentBlock,
} from "./types.ts";

// Classifying a failure. `ValidationError` is exported as a constructor too:
// adapter request parsers raise it so a malformed body and a rejected message
// reach the caller as one kind of error.
export { classifyCoreError, type CoreErrorInfo } from "../errors.ts";
export { parseJsonObject, ValidationError } from "../validation.ts";
