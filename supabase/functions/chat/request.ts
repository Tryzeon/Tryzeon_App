/**
 * Structural narrowing only — every domain invariant (non-empty history, known
 * roles, size caps) is enforced by `validateChatParams` inside `runChatAgent`,
 * the single guard all entry points share. Hence the unchecked cast below.
 *
 * `onEvent` is deliberately absent: it is how the caller wants progress
 * delivered, not something the wire can ask for, so the entry point attaches it.
 */
import {
  type ChatMessage,
  type ChatParams,
  parseJsonObject,
  ValidationError,
} from "../_shared/chat/index.ts";

/**
 * Takes raw text rather than pre-parsed JSON so that a malformed body raises the
 * same ValidationError as a malformed field, and the entry point needs no
 * special case to turn one into a 400.
 */
export function parseChatParams(rawBody: string, userId: string): ChatParams {
  const b = parseJsonObject(rawBody);

  if (!Array.isArray(b.messages)) {
    throw new ValidationError("messages must be an array");
  }

  return { userId, messages: b.messages as ChatMessage[] };
}
