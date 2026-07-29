/**
 * This channel's conversation memory.
 *
 * The chat core takes a whole transcript and hands back the turns to append
 * (`ChatResult.messages`), but LINE has no client holding one between messages
 * — so this is where a conversation lives. `validateChatParams` already names
 * this caller: "a LINE adapter's stored conversation" is one of the entry
 * points its guard exists for.
 */
import type { ChatMessage, ContentBlock } from "../_shared/chat/index.ts";
import { clampProductName, type LineProduct } from "./product-card.ts";
import { redis } from "../_shared/redis.ts";

const KEY_PREFIX = "line:conv:";

/**
 * How long a conversation survives without a turn.
 *
 * This is the timeout rule in its entirety — there is no stored timestamp and
 * nothing compares one, because an expired key and an ended conversation are
 * the same event. Thirty minutes is one shopping session: someone who comes
 * back the next day is starting a new subject, not continuing this one.
 */
const IDLE_TTL_SECONDS = 30 * 60;

/** The slice of the Redis client this module uses, so tests can substitute it. */
export interface RedisLike {
  get(key: string): Promise<unknown>;
  set(key: string, value: unknown, opts: { ex: number }): Promise<unknown>;
}

export interface ConversationStore {
  /** The stored transcript, or an empty one when there is none to read. */
  load(lineUserId: string): Promise<ChatMessage[]>;
  /** Replaces the transcript and refreshes the idle window. */
  save(lineUserId: string, messages: ChatMessage[]): Promise<void>;
}

/**
 * The Redis-backed store — named for the capability it uses, not for the vendor
 * hosting it, which `_shared/redis.ts` owns and is the only module that should
 * know. Nothing below reaches past `get`/`set`.
 *
 * Keyed by the LINE account rather than by the auth user it maps to: the two
 * are 1:1, and the LINE id is in hand before the account is resolved, so keying
 * by it leaves this layer independent of the identity mapping entirely.
 *
 * Neither method throws, and that is the contract callers are written against
 * rather than an implementation detail. Memory is an enhancement — losing it
 * costs continuity, not the user's answer — so an outage degrades to a turn of
 * one. This is the same fail-open judgement `checkRateLimit` makes, and it
 * lives here so that no handler needs an error path for it.
 */
export function redisConversations(client: RedisLike = redis()): ConversationStore {
  return {
    async load(lineUserId) {
      try {
        const stored = await client.get(KEY_PREFIX + lineUserId);
        return Array.isArray(stored) ? stored as ChatMessage[] : [];
      } catch (err) {
        console.warn("line-webhook conversation load failed:", err);
        return [];
      }
    },
    async save(lineUserId, messages) {
      try {
        await client.set(KEY_PREFIX + lineUserId, messages, { ex: IDLE_TTL_SECONDS });
      } catch (err) {
        console.warn("line-webhook conversation save failed:", err);
      }
    },
  };
}

/**
 * The answer as it is stored: a recommended item keeps its id and loses its row.
 *
 * The item's full data was already replayed to the model in the paired
 * `tool_result`, so storing it again grows the transcript for nothing —
 * `toModelMessages` reads `b.id ?? b.item?.id`, and the app's own wire format
 * sends the id alone for exactly this reason (`chat_wire.dart`). A block naming
 * no id is dropped: it can be neither rendered nor referred to.
 *
 * A fixed point, because every turn re-dehydrates the prior turns along with
 * the new one rather than tracking which parts have already been through here.
 */
function dehydrateBlock(block: ContentBlock): ContentBlock | null {
  if (block?.type !== "product" && block?.type !== "wardrobe") return block;
  const id = block.id ?? block.item?.id;
  return id ? { type: block.type, id: String(id) } : null;
}

export function dehydrateMessages(messages: ChatMessage[]): ChatMessage[] {
  return messages.map((message) => ({
    role: message.role,
    content: message.content
      .map(dehydrateBlock)
      .filter((block): block is ContentBlock => block !== null),
  }));
}

/**
 * One product try-on, as a turn of the transcript.
 *
 * A `user` message because `ChatRole` has only the two roles and this is
 * something the user did. It carries the id so the model can name the same
 * product in a product block next turn, and the name so it can speak about it
 * in prose; the name is clamped because `products.name` has no length
 * constraint and one absurd title should not crowd out the conversation.
 */
export function tryonNote(product: LineProduct): ChatMessage {
  return {
    role: "user",
    content: [{
      type: "text",
      text: `（使用者剛試穿了商品 id:${product.id}「${clampProductName(product.name)}」）`,
    }],
  };
}

/**
 * One forwarded photo, as a turn of the transcript.
 *
 * A `user` message for the same reason {@link tryonNote} is: `ChatRole` has
 * only the two roles and this is something the user did.
 *
 * Where it differs is what it claims. {@link tryonNote} says the user *tried on*
 * a product, so its caller writes it only when the generation succeeded; this
 * one says only that a photo arrived, which is true whether or not the try-on
 * that followed produced anything. So its caller writes it unconditionally of
 * the generation's result — it still skips this when there is no description to
 * write — and a generation failure still leaves the agent able to answer "那有
 * 沒有類似的".
 *
 * The description arrives already trimmed and capped (`describeGarment` in
 * `garment-analysis.ts`), so nothing is clamped again here — one cap, stated in
 * the module that also states it to the model.
 */
export function photoNote(description: string): ChatMessage {
  return {
    role: "user",
    content: [{
      type: "text",
      text: `（使用者傳了一張衣物照片：${description}）`,
    }],
  };
}
