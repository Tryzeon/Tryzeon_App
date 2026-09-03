/**
 * Never throws, because `ConversationStore` never does: fail-open lives inside
 * the real store and is tested there.
 */
import type { ChatMessage } from "../_shared/chat/index.ts";
import type { ConversationStore } from "./conversation.ts";

export interface FakeConversations {
  store: ConversationStore;
  writes: ChatMessage[][];
}

/**
 * Seeded with `prior` until a key is written. `onSave` fires before the write is
 * recorded, so a test can interleave it with other doubles to assert ordering.
 */
export function fakeConversations(
  opts: { prior?: ChatMessage[]; onSave?: () => void } = {},
): FakeConversations {
  const writes: ChatMessage[][] = [];
  const prior = opts.prior ?? [];
  const saved = new Map<string, ChatMessage[]>();
  return {
    writes,
    store: {
      load: (lineUserId) => Promise.resolve(saved.get(lineUserId) ?? prior),
      save: (lineUserId, messages) => {
        opts.onSave?.();
        writes.push(messages);
        saved.set(lineUserId, messages);
        return Promise.resolve();
      },
    },
  };
}
