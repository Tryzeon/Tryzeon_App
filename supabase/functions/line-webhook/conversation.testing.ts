/**
 * Test double for the conversation store, shared by the chat and try-on
 * handler tests.
 *
 * Not a `*.test.ts` file, so the runner does not collect it and nothing in
 * production imports it — the arrangement `_shared/quota.testing.ts` uses.
 *
 * It never throws, because `ConversationStore` never does: fail-open lives
 * inside the real store and is tested there, so a double that threw would
 * assert behaviour the handlers are deliberately not written against.
 */
import type { ChatMessage } from "../_shared/chat/index.ts";
import type { ConversationStore } from "./conversation.ts";

export interface FakeConversations {
  store: ConversationStore;
  /** Every `save`, in order. */
  writes: ChatMessage[][];
}

/**
 * A Map-backed in-memory store, seeded with `prior` for any key nothing has
 * been written to yet. `onSave` fires before the write is recorded, so a test
 * can interleave it with other doubles to assert ordering.
 *
 * `load` returns the most recent `save` for that key rather than always `prior`:
 * a fixed-`prior` double could not exercise a try-on note saved by one handler
 * being read back by the next chat turn.
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
