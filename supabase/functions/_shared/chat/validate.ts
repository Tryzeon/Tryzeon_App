/**
 * The core's domain guard.
 *
 * `runChatAgent` calls it before charging anything, so every entry point (the
 * app's HTTP body, a LINE adapter's stored conversation) is checked by the same
 * rules rather than by whatever its own parser happened to look at.
 *
 * What it checks is the transcript's *structure* — roles, shape, size — and not
 * the block vocabulary. `toModelMessages` already ignores blocks it has no
 * mapping for, and a guard that rejected unknown types would have to be edited
 * every time the answer format grows a case, breaking stored conversations
 * written by an older deploy. Size is the exception: replay cost is unbounded
 * without a cap, so `MAX_MESSAGES` and `MAX_TEXT_LENGTH` are enforced here and
 * nowhere else.
 */
import { requireString, ValidationError } from "../validation.ts";
import { LIMITS } from "./types.ts";
import type { ChatMessage, ChatParams } from "./types.ts";

const ROLES = new Set(["user", "assistant"]);

/** Throws unless the message is a well-formed turn of the transcript. */
function checkMessage(message: ChatMessage, index: number): void {
  if (typeof message !== "object" || message === null) {
    throw new ValidationError(`messages[${index}] must be an object`);
  }
  if (!ROLES.has(message.role)) {
    throw new ValidationError(
      `messages[${index}].role must be 'user' or 'assistant'`,
    );
  }
  if (!Array.isArray(message.content)) {
    throw new ValidationError(`messages[${index}].content must be an array`);
  }

  for (let i = 0; i < message.content.length; i++) {
    const block = message.content[i];
    if (typeof block !== "object" || block === null) {
      throw new ValidationError(
        `messages[${index}].content[${i}] must be an object`,
      );
    }
    if (typeof block.text === "string" && block.text.length > LIMITS.MAX_TEXT_LENGTH) {
      throw new ValidationError(
        `messages[${index}].content[${i}].text too long ` +
          `(max ${LIMITS.MAX_TEXT_LENGTH})`,
      );
    }
  }
}

/**
 * Guard the core's domain invariants and return the params the turn should run
 * on.
 *
 * It returns rather than merely asserting for the same reason
 * `validateTryonParams` does: handing the checked value back means the
 * orchestrator cannot accidentally read the raw input instead. Unlike try-on's
 * it has nothing to normalize — a transcript is passed through as sent — so it
 * returns the input itself rather than copying up to `MAX_MESSAGES` messages to
 * produce an identical one.
 */
export function validateChatParams(params: ChatParams): ChatParams {
  requireString(params.userId, "userId");

  if (!Array.isArray(params.messages) || params.messages.length === 0) {
    throw new ValidationError("messages must be a non-empty array");
  }
  if (params.messages.length > LIMITS.MAX_MESSAGES) {
    throw new ValidationError(
      `too many messages (max ${LIMITS.MAX_MESSAGES})`,
    );
  }
  params.messages.forEach(checkMessage);

  return params;
}
