import { assertEquals } from "jsr:@std/assert";
import {
  handleImageMessage,
  handleProductTryon,
  type ProductTryonDeps,
  type TryonHandlerDeps,
} from "./tryon-handler.ts";
import { QuotaExceededError } from "../_shared/quota.ts";
import type { LineApi } from "./line-api.ts";
import type { LineProduct } from "./product-card.ts";
import { fakeConversations } from "./conversation.testing.ts";

const USER = "Uline123";

interface Sent {
  replies: object[][];
  pushes: object[][];
}

function fakeLine(overrides: Partial<LineApi> = {}): { line: LineApi; sent: Sent } {
  const sent: Sent = { replies: [], pushes: [] };
  const line: LineApi = {
    reply: (_token, messages) => {
      sent.replies.push(messages);
      return Promise.resolve();
    },
    push: (_to, messages) => {
      sent.pushes.push(messages);
      return Promise.resolve();
    },
    getContent: () => Promise.resolve(new Uint8Array([1, 2, 3])),
    showLoading: () => Promise.resolve(),
    ...overrides,
  };
  return { line, sent };
}

/** Deps with every collaborator stubbed; each test overrides what it cares about. */
function makeDeps(over: Partial<TryonHandlerDeps> = {}): TryonHandlerDeps {
  return {
    // deno-lint-ignore no-explicit-any
    admin: {} as any,
    line: fakeLine().line,
    liffOnboardUrl: "https://liff.example/onboard",
    getOrCreateUserId: () => Promise.resolve("user-1"),
    getAvatarPath: () => Promise.resolve("user-1/avatar.jpg"),
    runJob: () =>
      Promise.resolve({
        kind: "image",
        imageUrl: "https://img.example/result.jpg",
        usage: null,
        // deno-lint-ignore no-explicit-any
      } as any),
    ...over,
  };
}

const event = { replyToken: "rt", sourceUserId: USER, messageId: "m1" };

// deno-lint-ignore no-explicit-any
const textOf = (message: object) => (message as any).text as string;

Deno.test("a sender with no model photo is asked to onboard, and nothing is generated", async () => {
  const { line, sent } = fakeLine();
  let ran = false;
  await handleImageMessage(
    makeDeps({
      line,
      getAvatarPath: () => Promise.resolve(null),
      runJob: () => {
        ran = true;
        // deno-lint-ignore no-explicit-any
        return Promise.resolve({} as any);
      },
    }),
    event,
  );

  assertEquals(ran, false);
  assertEquals(sent.pushes, []);
  assertEquals(sent.replies.length, 1);
  // deno-lint-ignore no-explicit-any
  assertEquals((sent.replies[0][0] as any).type, "template");
});

Deno.test("a garment image is acknowledged, then the result is pushed", async () => {
  const { line, sent } = fakeLine();
  await handleImageMessage(makeDeps({ line }), event);

  assertEquals(sent.replies.length, 1);
  assertEquals(textOf(sent.replies[0][0]), "收到，正在試穿，請稍等！");
  assertEquals(sent.pushes.length, 1);
  assertEquals(sent.pushes[0][0], {
    type: "image",
    originalContentUrl: "https://img.example/result.jpg",
    previewImageUrl: "https://img.example/result.jpg",
  });
});

Deno.test("an image LINE will not hand over is reported as a download failure", async () => {
  const { line, sent } = fakeLine({
    getContent: () => Promise.reject(new Error("410 gone")),
  });
  let ran = false;
  await handleImageMessage(
    makeDeps({
      line,
      runJob: () => {
        ran = true;
        // deno-lint-ignore no-explicit-any
        return Promise.resolve({} as any);
      },
    }),
    event,
  );

  assertEquals(ran, false);
  assertEquals(sent.pushes.length, 1);
  assertEquals(textOf(sent.pushes[0][0]), "這張圖讀取失敗，麻煩再傳一次。");
});

Deno.test("an exhausted quota is reported in try-on's own words", async () => {
  const { line, sent } = fakeLine();
  await handleImageMessage(
    // `QuotaExceededError` carries the usage row it hit; null is fine here.
    makeDeps({ line, runJob: () => Promise.reject(new QuotaExceededError(null)) }),
    event,
  );

  assertEquals(sent.pushes.length, 1);
  assertEquals(textOf(sent.pushes[0][0]), "今日試穿次數已用完，明天再回來試。");
});

const PID = "8f14e45f-ceea-467a-9c8d-1b2c3d4e5f60";

const productEvent = { replyToken: "rt", sourceUserId: USER, productId: PID };

const someProduct = (over: Partial<LineProduct> = {}): LineProduct => ({
  id: PID,
  name: "短版牛仔外套",
  price: 1280,
  imageUrl: "https://img.example/stores/s1/p1.jpg",
  storeName: "某店",
  purchaseUrl: null,
  ...over,
});

function makeProductDeps(over: Partial<ProductTryonDeps> = {}): ProductTryonDeps {
  return {
    ...makeDeps(),
    imagesBaseUrl: "https://img.example",
    fetchProduct: () => Promise.resolve(someProduct()),
    conversations: fakeConversations().store,
    ...over,
  };
}

Deno.test("a product that is gone is said so, and no quota is spent", async () => {
  const { line, sent } = fakeLine();
  let ran = false;
  await handleProductTryon(
    makeProductDeps({
      line,
      fetchProduct: () => Promise.resolve(null),
      runJob: () => {
        ran = true;
        // deno-lint-ignore no-explicit-any
        return Promise.resolve({} as any);
      },
    }),
    productEvent,
  );

  assertEquals(ran, false);
  assertEquals(sent.pushes, []);
  assertEquals(textOf(sent.replies[0][0]), "這件商品已經下架了，換一件再試試。");
});

Deno.test("tapping try-on with no model photo asks to onboard first", async () => {
  const { line, sent } = fakeLine();
  await handleProductTryon(
    makeProductDeps({ line, getAvatarPath: () => Promise.resolve(null) }),
    productEvent,
  );

  assertEquals(sent.pushes, []);
  // deno-lint-ignore no-explicit-any
  assertEquals((sent.replies[0][0] as any).type, "template");
});

Deno.test("the product is named while waiting, and tried on by reference", async () => {
  const { line, sent } = fakeLine();
  // deno-lint-ignore no-explicit-any
  const jobs: any[] = [];
  await handleProductTryon(
    makeProductDeps({
      line,
      // deno-lint-ignore no-explicit-any
      runJob: (_clients: any, params: any) => {
        jobs.push(params);
        return Promise.resolve({
          kind: "image",
          imageUrl: "https://img.example/result.jpg",
          usage: null,
          // deno-lint-ignore no-explicit-any
        } as any);
      },
    }),
    productEvent,
  );

  assertEquals(
    textOf(sent.replies[0][0]),
    "收到，正在幫你試穿「短版牛仔外套」，請稍等！",
  );
  // The catalog product goes in as a reference, so the core resolves its images
  // and builds the garment description — no bytes travel through this adapter.
  assertEquals(jobs[0].garments, [{ productId: PID }]);
});

Deno.test("the result card carries the product back with the image", async () => {
  const { line, sent } = fakeLine();
  await handleProductTryon(
    makeProductDeps({
      line,
      fetchProduct: () =>
        Promise.resolve(someProduct({ purchaseUrl: "https://shop.example/p1" })),
    }),
    productEvent,
  );

  // deno-lint-ignore no-explicit-any
  const message = sent.pushes[0][0] as any;
  assertEquals(message.type, "flex");
  assertEquals(message.altText, "為你試穿了 短版牛仔外套");
  assertEquals(message.contents.hero.url, "https://img.example/result.jpg");
  assertEquals(message.contents.hero.aspectRatio, "9:16");
  assertEquals(message.contents.body.contents[0].text, "短版牛仔外套");
  assertEquals(message.contents.body.contents[1].contents[1].text, "1,280");
  assertEquals(message.contents.footer.contents[0].action.uri, "https://shop.example/p1");
});

Deno.test("a result card for a product with no buyable link has no footer", async () => {
  const { line, sent } = fakeLine();
  await handleProductTryon(makeProductDeps({ line }), productEvent);

  // deno-lint-ignore no-explicit-any
  assertEquals((sent.pushes[0][0] as any).contents.footer, undefined);
});

Deno.test("an over-long product name is clamped in the result card's altText", async () => {
  const { line, sent } = fakeLine();
  const longName = "衣".repeat(60);
  await handleProductTryon(
    makeProductDeps({ line, fetchProduct: () => Promise.resolve(someProduct({ name: longName })) }),
    productEvent,
  );

  // deno-lint-ignore no-explicit-any
  const message = sent.pushes[0][0] as any;
  const altText = message.altText as string;
  assertEquals(altText.length <= 400, true);
  assertEquals(altText, `為你試穿了 ${"衣".repeat(40)}…`);
});

Deno.test("an exhausted quota during a product try-on pushes the quota text, not a card", async () => {
  const { line, sent } = fakeLine();
  await handleProductTryon(
    makeProductDeps({
      line,
      runJob: () => Promise.reject(new QuotaExceededError(null)),
    }),
    productEvent,
  );

  // A regression that reused the success path here would push
  // `productResultMessage(undefined, product)` — a flex card whose
  // `hero.url` LINE rejects outright — so this asserts both the count and
  // the exact (non-flex) message.
  assertEquals(sent.pushes.length, 1);
  assertEquals(sent.pushes[0][0], {
    type: "text",
    text: "今日試穿次數已用完，明天再回來試。",
  });
});

Deno.test("a completed product try-on becomes part of the conversation", async () => {
  const { line } = fakeLine();
  const prior = [{
    role: "assistant" as const,
    content: [{ type: "text", text: "這件如何？" }],
  }];
  const conversations = fakeConversations({ prior });

  await handleProductTryon(
    makeProductDeps({ line, conversations: conversations.store }),
    productEvent,
  );

  // Appended, not replacing: the card the user tapped came from the turn
  // before it, and "這件配什麼褲子" needs both.
  assertEquals(conversations.writes.length, 1);
  assertEquals(conversations.writes[0], [
    ...prior,
    {
      role: "user",
      content: [{
        type: "text",
        text: `（使用者剛試穿了商品 id:${PID}「短版牛仔外套」）`,
      }],
    },
  ]);
});

Deno.test("a try-on that never happened is not recorded", async () => {
  const { line } = fakeLine();
  const conversations = fakeConversations();

  await handleProductTryon(
    makeProductDeps({
      line,
      conversations: conversations.store,
      runJob: () => Promise.reject(new QuotaExceededError(null)),
    }),
    productEvent,
  );

  assertEquals(conversations.writes, []);
});

Deno.test("the result card is pushed before the conversation is written", async () => {
  const trace: string[] = [];
  const { line } = fakeLine({
    push: () => {
      trace.push("push");
      return Promise.resolve();
    },
  });
  const conversations = fakeConversations({ onSave: () => trace.push("save") });

  await handleProductTryon(
    makeProductDeps({ line, conversations: conversations.store }),
    productEvent,
  );

  assertEquals(trace, ["push", "save"]);
});
