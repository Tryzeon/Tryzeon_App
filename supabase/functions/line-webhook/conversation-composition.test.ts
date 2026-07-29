/**
 * The branch's headline story, exercised end to end: try on a card, then ask
 * about it in chat, and have the second turn see the first.
 *
 * Every piece here — dehydration, the try-on note, loading and saving in each
 * handler — is covered in isolation in `conversation.test.ts`,
 * `tryon-handler.test.ts` and `chat-handler.test.ts`. None of those prove the
 * composition, because it only exists across two handlers sharing one store,
 * and `fakeConversations`'s old fixed-`prior` behaviour could not represent a
 * write from one call being read back by the next. This is a separate file
 * rather than an addition to either handler's suite because the scenario
 * belongs to neither on its own.
 */
import { assertEquals } from "jsr:@std/assert";
import { handleProductTryon, type ProductTryonDeps } from "./tryon-handler.ts";
import { handleTextMessage, type ChatHandlerDeps } from "./chat-handler.ts";
import {
  type ChatMessage,
  type ChatParams,
  type ContentBlock,
  type RunChatAgentDeps,
  runChatAgent,
} from "../_shared/chat/index.ts";
import type { LineApi } from "./line-api.ts";
import type { LineProduct } from "./product-card.ts";
import { fakeConversations } from "./conversation.testing.ts";
import { tryonNote } from "./conversation.ts";

const USER = "Uline123";
const PID = "8f14e45f-ceea-467a-9c8d-1b2c3d4e5f60";

function fakeLine(): LineApi {
  return {
    reply: () => Promise.resolve(),
    push: () => Promise.resolve(),
    getContent: () => Promise.resolve(new Uint8Array()),
    showLoading: () => Promise.resolve(),
  };
}

const someProduct: LineProduct = {
  id: PID,
  name: "短版牛仔外套",
  price: 1280,
  imageUrl: "https://img.example/stores/s1/p1.jpg",
  storeName: "某店",
  purchaseUrl: null,
};

function fakeChat(blocks: ContentBlock[]) {
  const seen: { params: ChatParams; deps: RunChatAgentDeps }[] = [];
  const runChat: typeof runChatAgent = (_clients, params, deps = {}) => {
    seen.push({ params, deps });
    return Promise.resolve({ blocks, messages: [], usage: null });
  };
  return { runChat, seen };
}

Deno.test("a chat turn sees the try-on note the previous turn recorded", async () => {
  const prior: ChatMessage[] = [
    { role: "assistant", content: [{ type: "text", text: "這件如何？" }] },
  ];
  const conversations = fakeConversations({ prior });
  const line = fakeLine();

  const productDeps: ProductTryonDeps = {
    // deno-lint-ignore no-explicit-any
    admin: {} as any,
    line,
    liffOnboardUrl: "https://liff.example/onboard",
    imagesBaseUrl: "https://img.example",
    conversations: conversations.store,
    getOrCreateUserId: () => Promise.resolve("user-1"),
    getAvatarPath: () => Promise.resolve("user-1/avatar.jpg"),
    fetchProduct: () => Promise.resolve(someProduct),
    runJob: () =>
      Promise.resolve({
        kind: "image",
        imageUrl: "https://img.example/result.jpg",
        usage: null,
        // deno-lint-ignore no-explicit-any
      } as any),
  };

  await handleProductTryon(productDeps, {
    replyToken: "rt",
    sourceUserId: USER,
    productId: PID,
  });

  const chat = fakeChat([{ type: "text", text: "配深色長褲" }]);
  const chatDeps: ChatHandlerDeps = {
    // deno-lint-ignore no-explicit-any
    admin: {} as any,
    line,
    imagesBaseUrl: "https://img.example",
    conversations: conversations.store,
    getOrCreateUserId: () => Promise.resolve("user-1"),
    runChat: chat.runChat,
  };

  await handleTextMessage(chatDeps, {
    replyToken: "rt",
    sourceUserId: USER,
    text: "這件配什麼褲子",
  });

  // Provable only because the store double now remembers what was written —
  // this is exactly what makes "試穿完直接問這件配什麼褲子" work.
  assertEquals(chat.seen[0].params.messages, [
    ...prior,
    tryonNote(someProduct),
    { role: "user", content: [{ type: "text", text: "這件配什麼褲子" }] },
  ]);
});
