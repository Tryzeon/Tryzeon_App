import type { ChatMessage, ContentBlock } from "../_shared/chat/index.ts";
import { clampProductName, type ProductInfo } from "./product-card.ts";
import { tagLine, type WardrobeItemInfo } from "./wardrobe-card.ts";
import { redis } from "../_shared/redis.ts";

const KEY_PREFIX = "line:conv:";

/** Thirty minutes is one shopping session; an expired key ends the conversation. */
const IDLE_TTL_SECONDS = 30 * 60;

export interface RedisLike {
  get(key: string): Promise<unknown>;
  set(key: string, value: unknown, opts: { ex: number }): Promise<unknown>;
}

export interface ConversationStore {
  load(lineUserId: string): Promise<ChatMessage[]>;
  save(lineUserId: string, messages: ChatMessage[]): Promise<void>;
}

/**
 * Keyed by the LINE account rather than by the auth user it maps to: the two are
 * 1:1, and the LINE id is in hand before the account is resolved.
 *
 * Neither method throws, and that is the contract callers are written against:
 * an outage degrades to a turn of one, so no handler needs an error path for it.
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
 * A recommended item keeps its id and loses its row: the full data was already
 * replayed to the model in the paired `tool_result`, and `toModelMessages` reads
 * `b.id ?? b.item?.id`.
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

export function tryonNote(product: ProductInfo): ChatMessage {
  return {
    role: "user",
    content: [{
      type: "text",
      text: `（使用者剛試穿了商品 id:${product.id}「${clampProductName(product.name)}」）`,
    }],
  };
}

/**
 * Claims only that a photo arrived, not that a try-on succeeded, so its caller
 * writes it whatever the generation's result. The description arrives already
 * trimmed and capped by `describeGarment`.
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

/**
 * Carries the tags as well as the category because the chip this card offers
 * next is "幫我配這件" — the agent has to know what "這件" was to answer it,
 * and a bare "上衣" is not enough to pair anything with. Tags go through
 * `tagLine` because `wardrobe_items.tags` is unconstrained text.
 */
export function wardrobeTryonNote(item: WardrobeItemInfo): ChatMessage {
  const tags = item.tags.length > 0 ? ` ${tagLine(item.tags)}` : "";
  return {
    role: "user",
    content: [{
      type: "text",
      text:
        `（使用者剛試穿了自己衣櫃裡的單品 id:${item.id}「${item.categoryLabel}${tags}」）`,
    }],
  };
}
