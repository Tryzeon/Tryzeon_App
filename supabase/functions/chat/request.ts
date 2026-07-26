/**
 * The app's wire format for the `chat` function.
 *
 * Request parsing is an adapter concern: this JSON body is what the Flutter
 * client speaks, and no other chat caller speaks it (a LINE adapter reads its
 * conversation from storage and has no body at all).
 *
 * Structural narrowing only — every domain invariant (non-empty history, known
 * roles, size caps) is enforced by `validateChatParams` inside `runChatAgent`,
 * the single guard all entry points share. A malformed value survives decoding
 * as a typed shape and is rejected there, so this module never duplicates the
 * rules. Hence the unchecked cast below: it asserts the shape the wire format
 * is supposed to have, and the very next thing that happens to the result is
 * the core checking whether it really does.
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
 * Decode the raw request body into typed ChatParams, attaching the
 * caller-supplied (authenticated) userId.
 *
 * Takes the raw text rather than pre-parsed JSON: "the body is JSON" is part of
 * the wire format, and `parseJsonObject` is where every adapter agrees on what
 * that means, so malformed input raises the same ValidationError as a malformed
 * field and the entry point needs no special case to turn one into a 400.
 */
export function parseChatParams(rawBody: string, userId: string): ChatParams {
  const b = parseJsonObject(rawBody);

  if (!Array.isArray(b.messages)) {
    throw new ValidationError("messages must be an array");
  }

  return { userId, messages: b.messages as ChatMessage[] };
}
