/**
 * The composition exists only across two handlers sharing one store, so it
 * belongs to neither handler's suite on its own.
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
    getDisplayName: () => Promise.resolve(undefined),
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
  const runChat: typeof runChatAgent = (_client, params, deps) => {
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
    liffUrl: "https://liff.example",
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

  assertEquals(chat.seen[0].params.messages, [
    ...prior,
    tryonNote(someProduct),
    { role: "user", content: [{ type: "text", text: "這件配什麼褲子" }] },
  ]);
});
