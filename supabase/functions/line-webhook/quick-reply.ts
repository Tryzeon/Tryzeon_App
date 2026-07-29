/**
 * Quick replies, as LINE builds them.
 *
 * The sibling of `card-kit.ts`: that module owns how this channel *looks*, this
 * one owns how it offers a next step. Neither knows any copy — which chips a
 * message carries is `messages.ts`'s business, the same way the words on a card
 * are.
 *
 * Chips cost nothing against the messaging quota, which is why every dead end in
 * this feature can afford one.
 */

/** Chips LINE accepts on one message. */
const MAX_ITEMS = 13;

const chip = (action: object): object => ({ type: "action", action });

/**
 * A chip that types for the sender.
 *
 * `label` and `text` are separate on purpose: the text lands in the chat as
 * words the sender appears to have typed, so it has to read like their own
 * speech, while the label is a button and reads like one.
 *
 * It arrives at `handleTextMessage` exactly as a typed message does — which
 * costs a chat quota unit and a full agent turn, and is the point when the chip
 * needs the conversation behind it to mean anything.
 */
export const messageChip = (label: string, text: string): object =>
  chip({ type: "message", label, text });

/**
 * A chip that opens the photo library.
 *
 * The camera roll rather than the camera: a garment photo is usually a
 * screenshot or a saved picture, not something taken on the spot. No `imageUrl`
 * — LINE draws its own icon for this action kind, which is the whole reason this
 * feature needs no image assets.
 */
export const cameraRollChip = (label: string): object =>
  chip({ type: "cameraRoll", label });

/**
 * A chip that acts without the agent.
 *
 * Free and immediate where {@link messageChip} costs a turn, and it carries its
 * own parameters, so it still works when the stored conversation has expired.
 * `displayText` is not optional in practice: without it the tap leaves no trace
 * and the bot appears to start talking for no reason.
 */
export const postbackChip = (
  label: string,
  data: string,
  displayText: string,
): object => chip({ type: "postback", label, data, displayText });

/**
 * One message, wearing the chips it offers.
 *
 * An empty set returns the message untouched rather than an empty `items`
 * array, which LINE rejects — so a caller may compute "no next step" (an answer
 * that is only a follow-up question) without a branch of its own.
 */
export function withQuickReply(message: object, items: object[]): object {
  if (items.length === 0) return message;
  return { ...message, quickReply: { items: items.slice(0, MAX_ITEMS) } };
}

/**
 * One send, wearing the chips it offers — on its last message and only that one.
 *
 * A send carries up to five messages, and LINE does not document which quick
 * reply wins when several of them arrive dressed. Putting the chips on exactly
 * one message means the result never depends on that unwritten rule.
 *
 * An empty send is returned untouched: `messages.at(-1)` would be `undefined`,
 * and dressing it yields an object with a `quickReply` and no `type` — which
 * LINE rejects, taking the whole send with it.
 */
export function dressLast(messages: object[], items: object[]): object[] {
  if (messages.length === 0 || items.length === 0) return messages;
  return [...messages.slice(0, -1), withQuickReply(messages.at(-1)!, items)];
}
