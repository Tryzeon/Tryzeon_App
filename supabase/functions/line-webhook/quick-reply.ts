/** Chips cost nothing against the messaging quota. */

const MAX_ITEMS = 13;

const chip = (action: object): object => ({ type: "action", action });

/**
 * `text` lands in the chat as words the sender appears to have typed, and
 * arrives at `handleTextMessage` exactly as a typed message does — costing a
 * chat quota unit and a full agent turn.
 */
export const messageChip = (label: string, text: string): object =>
  chip({ type: "message", label, text });

/** No `imageUrl`: LINE draws its own icon for this action kind. */
export const cameraRollChip = (label: string): object =>
  chip({ type: "cameraRoll", label });

/**
 * `displayText` is not optional in practice: without it the tap leaves no trace
 * and the bot appears to start talking for no reason.
 */
export const postbackChip = (
  label: string,
  data: string,
  displayText: string,
): object => chip({ type: "postback", label, data, displayText });

/**
 * `uri` must be absolute http(s): LINE rejects anything else, and a rejected
 * action fails the whole send rather than the one chip. Unchecked here because
 * every caller builds it from this deployment's own configuration — a bad value
 * is a misconfigured environment, which `index.ts` already refuses to start on,
 * not something a sender can cause.
 */
export const uriChip = (label: string, uri: string): object =>
  chip({ type: "uri", label, uri });

/**
 * An empty set returns the message untouched rather than an empty `items`
 * array, which LINE rejects.
 */
export function withQuickReply(message: object, items: object[]): object {
  if (items.length === 0) return message;
  return { ...message, quickReply: { items: items.slice(0, MAX_ITEMS) } };
}

/**
 * Chips go on the last message only: LINE does not document which quick reply
 * wins when several messages of one send carry them. An empty send is returned
 * untouched — dressing `undefined` yields an object with a `quickReply` and no
 * `type`, which LINE rejects, taking the whole send with it.
 */
export function dressLast(messages: object[], items: object[]): object[] {
  if (messages.length === 0 || items.length === 0) return messages;
  return [...messages.slice(0, -1), withQuickReply(messages.at(-1)!, items)];
}
