import { assertEquals } from "jsr:@std/assert";
import {
  handleImageTryon,
  handleProductTryon,
  type ImageTryonDeps,
  type ProductTryonDeps,
  type TryonHandlerDeps,
} from "./tryon-handler.ts";
import { QuotaExceededError } from "../_shared/quota.ts";
import { GenerationFailedError } from "../_shared/tryon/errors.ts";
import type { LineApi } from "./line-api.ts";
import type { LineProduct } from "./product-card.ts";
import { fakeConversations } from "./conversation.testing.ts";
import { photoNote } from "./conversation.ts";

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

/** What both paths share, every collaborator stubbed. */
function baseDeps(): TryonHandlerDeps {
  return {
    // deno-lint-ignore no-explicit-any
    admin: {} as any,
    line: fakeLine().line,
    liffUrl: "https://liff.example",
    conversations: fakeConversations().store,
    getOrCreateUserId: () => Promise.resolve("user-1"),
    getAvatarPath: () => Promise.resolve("user-1/avatar.jpg"),
    runJob: () =>
      Promise.resolve({
        kind: "image",
        imageUrl: "https://img.example/result.jpg",
        usage: null,
        // deno-lint-ignore no-explicit-any
      } as any),
  };
}

/** Photo-path deps; each test overrides what it cares about. */
function makeDeps(over: Partial<ImageTryonDeps> = {}): ImageTryonDeps {
  return {
    ...baseDeps(),
    describeGarment: () => Promise.resolve("淺藍色寬鬆棉質抽繩長褲"),
    ...over,
  };
}

const event = { replyToken: "rt", sourceUserId: USER, messageId: "m1" };

// deno-lint-ignore no-explicit-any
const textOf = (message: object) => (message as any).text as string;

/** A message with its chips stripped, for assertions that are not about them. */
const bare = (message: object) => {
  // deno-lint-ignore no-explicit-any
  const { quickReply: _ignored, ...rest } = message as Record<string, any>;
  return rest;
};

/** The labels a message offers, in order. */
const chipLabels = (message: object): string[] =>
  // deno-lint-ignore no-explicit-any
  ((message as any).quickReply?.items ?? []).map((i: any) => i.action.label);

/**
 * The full actions a message's chips carry, in order.
 *
 * Unlike {@link chipLabels}, this keeps `text` — the string a `message` chip
 * sends as though the sender typed it — next to the `label` a test asserts
 * against, so the two are read side by side rather than one going unchecked.
 */
const chipActions = (message: object): object[] =>
  // deno-lint-ignore no-explicit-any
  ((message as any).quickReply?.items ?? []).map((i: any) => i.action);

Deno.test("a sender with no model photo is asked to onboard, and nothing is generated", async () => {
  const { line, sent } = fakeLine();
  let ran = false;
  await handleImageTryon(
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
  await handleImageTryon(makeDeps({ line }), event);

  assertEquals(sent.replies.length, 1);
  assertEquals(textOf(sent.replies[0][0]), "收到，正在試穿，請稍等！");
  assertEquals(sent.pushes.length, 1);
  assertEquals(bare(sent.pushes[0][0]), {
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
  await handleImageTryon(
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
  await handleImageTryon(
    // `QuotaExceededError` carries the usage row it hit; null is fine here.
    makeDeps({ line, runJob: () => Promise.reject(new QuotaExceededError(null)) }),
    event,
  );

  assertEquals(sent.pushes.length, 1);
  assertEquals(textOf(sent.pushes[0][0]), "今日試穿次數已用完，明天再回來試。");
});

Deno.test("a forwarded photo becomes part of the conversation", async () => {
  const prior = [{
    role: "assistant" as const,
    content: [{ type: "text", text: "傳張照片給我" }],
  }];
  const conversations = fakeConversations({ prior });

  await handleImageTryon(makeDeps({ conversations: conversations.store }), event);

  assertEquals(conversations.writes.length, 1);
  assertEquals(conversations.writes[0], [
    ...prior,
    photoNote("淺藍色寬鬆棉質抽繩長褲"),
  ]);
});

Deno.test("what the user sent is recorded even when nothing could be generated", async () => {
  // The note says a photo arrived, not that it was worn — true either way. So a
  // sender who reads "這張沒能生成" can still follow up with "那有沒有類似的".
  const conversations = fakeConversations();

  await handleImageTryon(
    makeDeps({
      conversations: conversations.store,
      runJob: () => Promise.reject(new QuotaExceededError(null)),
    }),
    event,
  );

  assertEquals(conversations.writes.length, 1);
  assertEquals(conversations.writes[0], [photoNote("淺藍色寬鬆棉質抽繩長褲")]);
});

Deno.test("an unreadable photo costs the note, not the try-on", async () => {
  const { line, sent } = fakeLine();
  const conversations = fakeConversations();

  await handleImageTryon(
    makeDeps({
      line,
      conversations: conversations.store,
      describeGarment: () => Promise.resolve(null),
    }),
    event,
  );

  assertEquals(conversations.writes, []);
  assertEquals(sent.pushes.length, 1);
  assertEquals(bare(sent.pushes[0][0]), {
    type: "image",
    originalContentUrl: "https://img.example/result.jpg",
    previewImageUrl: "https://img.example/result.jpg",
  });
});

Deno.test("the photo is described from the same bytes the try-on wears", async () => {
  // One download, two readers, running together — the description must not cost
  // the sender a second wait on top of the ~30s generation.
  const seen: { userId: string; base64: string }[] = [];
  // deno-lint-ignore no-explicit-any
  const jobs: any[] = [];

  await handleImageTryon(
    makeDeps({
      describeGarment: (userId, base64) => {
        seen.push({ userId, base64 });
        return Promise.resolve("白襯衫");
      },
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
    event,
  );

  assertEquals(seen.length, 1);
  assertEquals(seen[0].userId, "user-1");
  assertEquals(seen[0].base64, jobs[0].garments[0].images[0].base64);
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
    ...baseDeps(),
    imagesBaseUrl: "https://img.example",
    fetchProduct: () => Promise.resolve(someProduct()),
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
  // `hero.url` LINE rejects outright — so this asserts both the count and,
  // with `quickReply` stripped by `bare()`, the message body underneath it.
  assertEquals(sent.pushes.length, 1);
  assertEquals(bare(sent.pushes[0][0]), {
    type: "text",
    text: "今日試穿次數已用完，明天再回來試。",
  });
  // The photo-path quota chip has coverage above; this is its product-path
  // counterpart.
  assertEquals(chipLabels(sent.pushes[0][0]), ["找衣服看看"]);
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

Deno.test("the result image is pushed before the conversation is written", async () => {
  const trace: string[] = [];
  const { line } = fakeLine({
    push: () => {
      trace.push("push");
      return Promise.resolve();
    },
  });
  const conversations = fakeConversations({ onSave: () => trace.push("save") });

  await handleImageTryon(makeDeps({ line, conversations: conversations.store }), event);

  assertEquals(trace, ["push", "save"]);
});

Deno.test("a stalled description does not hold back the result", async () => {
  // `Promise.all` would settle on the slower of the two, so a hung analysis
  // would keep the sender from the image they waited 30s for. The description
  // is context for the next turn; it is not what they are waiting on.
  const trace: string[] = [];
  let releaseDescription: (value: string | null) => void = () => {};
  const described = new Promise<string | null>((resolve) => {
    releaseDescription = resolve;
  });

  const { line } = fakeLine({
    push: () => {
      trace.push("push");
      // Only now let the description finish, so the push provably did not wait.
      releaseDescription("白襯衫");
      return Promise.resolve();
    },
  });
  const conversations = fakeConversations({ onSave: () => trace.push("save") });

  await handleImageTryon(
    makeDeps({ line, conversations: conversations.store, describeGarment: () => described }),
    event,
  );

  assertEquals(trace, ["push", "save"]);
  assertEquals(conversations.writes[0], [photoNote("白襯衫")]);
});

Deno.test("a finished photo try-on offers the next one, and the shop", async () => {
  const { line, sent } = fakeLine();
  await handleImageTryon(makeDeps({ line }), event);

  assertEquals(chipActions(sent.pushes[0][0]), [
    { type: "cameraRoll", label: "再試一件" },
    { type: "message", label: "找類似的商品", text: "幫我找類似剛剛那件的商品" },
    { type: "message", label: "幫我配這件", text: "幫我搭配剛剛那件" },
  ]);
});

Deno.test("a photo that would not generate offers another photo, not a retry", async () => {
  // There is nothing to retry: the garment was these bytes, and they are the
  // thing that failed. What the sender can do is send a clearer picture.
  const { line, sent } = fakeLine();
  await handleImageTryon(
    makeDeps({
      line,
      runJob: () => Promise.reject(new GenerationFailedError("no image")),
    }),
    event,
  );

  assertEquals(chipActions(sent.pushes[0][0]), [
    { type: "cameraRoll", label: "換一張再試" },
    { type: "message", label: "找類似的商品", text: "幫我找類似剛剛那件的商品" },
  ]);
});

Deno.test("a spent try-on quota offers the chat the sender still has", async () => {
  // `FeatureName` is "chat" | "tryon" | "tryon_video" — three separate counters,
  // so a spent try-on budget is not a spent conversation. Without this chip the
  // message is a dead end for the rest of the day.
  const { line, sent } = fakeLine();
  await handleImageTryon(
    makeDeps({ line, runJob: () => Promise.reject(new QuotaExceededError(null)) }),
    event,
  );

  assertEquals(chipLabels(sent.pushes[0][0]), ["找衣服看看"]);
});

Deno.test("a finished product try-on offers to build around it", async () => {
  const { line, sent } = fakeLine();
  await handleProductTryon(makeProductDeps({ line }), productEvent);

  assertEquals(chipActions(sent.pushes[0][0]), [
    { type: "message", label: "找類似的", text: "有沒有類似的其他商品" },
    { type: "message", label: "幫我配這件", text: "幫我搭配剛剛試穿的那件" },
    { type: "cameraRoll", label: "試我自己的衣服" },
  ]);
});

Deno.test("a product that would not generate can be retried by id alone", async () => {
  // The retry carries the product id in the postback, so it still works when the
  // stored conversation has expired — which is exactly when a `message` chip
  // asking for "類似的" would have nothing to be similar to.
  const { line, sent } = fakeLine();
  await handleProductTryon(
    makeProductDeps({
      line,
      runJob: () => Promise.reject(new GenerationFailedError("no image")),
    }),
    productEvent,
  );

  // deno-lint-ignore no-explicit-any
  const action = (sent.pushes[0][0] as any).quickReply.items[0].action;
  assertEquals(action.type, "postback");
  assertEquals(action.data, `a=tryon&pid=${PID}`);
  assertEquals(action.displayText, "試穿「短版牛仔外套」");
});

Deno.test("a product try-on puts no avatar on the job params", async () => {
  // The handler hands the photo to the core through `resolveAvatar`, never as a
  // params field: a caller-named avatar is what went stale.
  let seenAvatar: unknown = "unset";
  await handleProductTryon(
    makeProductDeps({
      // deno-lint-ignore no-explicit-any
      runJob: ((_clients: any, params: any) => {
        seenAvatar = params.avatar;
        return Promise.resolve({
          kind: "image",
          imageUrl: "https://img.example/result.jpg",
          usage: null,
          // deno-lint-ignore no-explicit-any
        } as any);
        // deno-lint-ignore no-explicit-any
      }) as any,
    }),
    productEvent,
  );

  assertEquals(seenAvatar, undefined);
});
