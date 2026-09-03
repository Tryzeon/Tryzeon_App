import { assertEquals } from "jsr:@std/assert";
import {
  chatErrorMessage,
  onboardingMessage,
  productTryonErrorMessage,
  productUnavailableMessage,
  tryonErrorMessage,
  wardrobeProcessingMessage,
  wardrobeUnavailableMessage,
  wardrobeResultMessage,
  wardrobeTryonErrorMessage,
  welcomeMessage,
} from "./messages.ts";
import type { LineProduct } from "./product-card.ts";
import { productTryonPostbackData, wardrobeTryonPostbackData } from "./postback.ts";
import type { WardrobeItemInfo } from "./wardrobe-card.ts";

const PID = "8f14e45f-ceea-467a-9c8d-1b2c3d4e5f60";
const LIFF = "https://liff.example";

const product: LineProduct = {
  id: PID,
  name: "短版牛仔外套",
  price: 1280,
  imageUrl: "https://img.example/stores/s1/p1.jpg",
  storeName: "某店",
  purchaseUrl: null,
};

/**
 * Full objects, not labels alone: a `message` chip's `text` is what lands in the
 * chat as though the sender typed it, so a test that only reads `label` would
 * let it drift from what the button promises without failing.
 */
const chipActions = (message: object): object[] =>
  // deno-lint-ignore no-explicit-any
  ((message as { quickReply?: { items: any[] } }).quickReply?.items ?? []).map(
    (i) => i.action,
  );

const templateUri = (message: object): string =>
  (message as { template: { actions: { uri: string }[] } }).template.actions[0].uri;

Deno.test("onboarding reaches both liff-web screens from one base URL", () => {
  const message = onboardingMessage("https://liff.example");

  assertEquals(templateUri(message), "https://liff.example/onboard");
  assertEquals(chipActions(message), [
    { type: "uri", label: "先逛逛商品", uri: "https://liff.example" },
    { type: "message", label: "這是什麼服務", text: "你是誰，你能幫我做什麼" },
  ]);
});

Deno.test("the welcome leads with what costs the sender nothing", () => {
  assertEquals(chipActions(welcomeMessage()), [
    { type: "message", label: "有什麼推薦", text: "有什麼推薦的商品嗎" },
    { type: "cameraRoll", label: "傳衣服照試穿" },
    { type: "message", label: "幫我配一套", text: "幫我配一套適合我的穿搭" },
  ]);
});

Deno.test("a spent chat quota offers the try-on the sender still has", () => {
  assertEquals(chipActions(chatErrorMessage("quota")), [
    { type: "cameraRoll", label: "直接傳衣服試穿" },
  ]);
});

Deno.test("an over-long message offers to ask again, not to resend the same one", () => {
  assertEquals(chipActions(chatErrorMessage("too_long")), [
    { type: "message", label: "有什麼推薦", text: "有什麼推薦的商品" },
  ]);
});

Deno.test("an unknown chat failure offers to re-ask, honestly labelled", () => {
  // Regression: the label promised to re-ask the question that just failed
  // while the text it typed on the sender's behalf was an unrelated request.
  assertEquals(chipActions(chatErrorMessage("unknown")), [
    { type: "message", label: "有什麼推薦", text: "有什麼推薦的商品嗎" },
    { type: "cameraRoll", label: "傳衣服照試穿" },
  ]);
});

Deno.test("a spent try-on quota offers the chat the sender still has", () => {
  assertEquals(chipActions(tryonErrorMessage("quota")), [
    { type: "message", label: "找衣服看看", text: "有什麼推薦的商品" },
  ]);
});

Deno.test("a photo that would not generate offers another photo, not a retry", () => {
  assertEquals(chipActions(tryonErrorMessage("generation")), [
    { type: "cameraRoll", label: "換一張再試" },
    { type: "message", label: "找類似的商品", text: "幫我找類似剛剛那件的商品" },
  ]);
});

Deno.test("an unreadable photo offers to resend it", () => {
  assertEquals(chipActions(tryonErrorMessage("download")), [
    { type: "cameraRoll", label: "重新傳一張" },
  ]);
});

Deno.test("an unknown try-on failure offers a plain retry", () => {
  assertEquals(chipActions(tryonErrorMessage("unknown")), [
    { type: "cameraRoll", label: "再試一次" },
  ]);
});

Deno.test("both try-on paths report a failed generation in the same words", () => {
  // One string naming both remedies: the two paths can act on different halves
  // of it — a photo cannot usefully be retried as-is, a catalog product can — so
  // saying only one of them would need two strings again.
  const text = "這件沒能生成，請換一件或再試一次看看！";

  assertEquals((tryonErrorMessage("generation") as { text: string }).text, text);
  assertEquals(
    (productTryonErrorMessage("generation", product, LIFF) as { text: string }).text,
    text,
  );
});

Deno.test("a spent try-on quota on the product path offers the chat the sender still has", () => {
  assertEquals(chipActions(productTryonErrorMessage("quota", product, LIFF)), [
    { type: "message", label: "找衣服看看", text: "有什麼推薦的商品" },
  ]);
});

Deno.test("a product that would not generate offers both remedies its text names", () => {
  // Without the catalog link, "請換一件" names a remedy with no button behind it.
  assertEquals(chipActions(productTryonErrorMessage("generation", product, LIFF)), [
    {
      type: "postback",
      label: "再試一次",
      data: productTryonPostbackData(PID),
      displayText: "試穿「短版牛仔外套」",
    },
    { type: "uri", label: "換一件試試", uri: LIFF },
  ]);
});

Deno.test("an unknown failure offers only the retry, not a different product", () => {
  // "出了點狀況，請稍後再試" is a fault on our side rather than this product's,
  // so a different product would likely fail the same way.
  assertEquals(chipActions(productTryonErrorMessage("unknown", product, LIFF)), [
    {
      type: "postback",
      label: "再試一次",
      data: productTryonPostbackData(PID),
      displayText: "試穿「短版牛仔外套」",
    },
  ]);
});

Deno.test("a product that is gone offers three ways to find another", () => {
  assertEquals(chipActions(productUnavailableMessage(LIFF)), [
    { type: "message", label: "有什麼推薦", text: "有什麼推薦的商品" },
    { type: "uri", label: "逛逛其他商品", uri: LIFF },
    { type: "cameraRoll", label: "試我自己的衣服" },
  ]);
});

Deno.test("a busy try-on offers no chip on either path", () => {
  assertEquals(chipActions(tryonErrorMessage("busy")), []);
  assertEquals(chipActions(productTryonErrorMessage("busy", product, LIFF)), []);
});

const wardrobeItem: WardrobeItemInfo = {
  id: "44444444-4444-4444-4444-444444444444",
  categoryLabel: "上衣",
  tags: ["寬鬆"],
};

Deno.test("the wardrobe acknowledgement names the kind of thing being tried on", () => {
  assertEquals(wardrobeProcessingMessage("上衣"), {
    type: "text",
    text: "收到，正在幫你試穿衣櫃裡這件上衣，請稍等！",
  });
});

Deno.test("the others bucket reads as 單品, not 其他, in the acknowledgement", () => {
  // 「其他」 is a bucket label, not a countable noun — 「試穿這件其他」 is
  // broken Chinese. `shoes` and `accessories` both remap to `others`
  // (20260616120000_remap_wardrobe_category_enum.sql), so this is not rare.
  assertEquals(wardrobeProcessingMessage("其他"), {
    type: "text",
    text: "收到，正在幫你試穿衣櫃裡這件單品，請稍等！",
  });
});

Deno.test("a vanished wardrobe item does not send the user shopping", () => {
  // deno-lint-ignore no-explicit-any
  const message = wardrobeUnavailableMessage() as any;

  assertEquals(message.text, "這件已經不在你的衣櫃裡了。");
  assertEquals(message.quickReply.items.length, 2);
});

Deno.test("the wardrobe result card leads with the way to shop", () => {
  // deno-lint-ignore no-explicit-any
  const card = wardrobeResultMessage("https://img/r.png", wardrobeItem) as any;

  assertEquals(card.contents.hero.url, "https://img/r.png");
  assertEquals(card.contents.hero.aspectRatio, "9:16");
  assertEquals(card.contents.footer, undefined);
  assertEquals(card.quickReply.items[0].action.text, "幫我找可以搭配剛剛試穿那件的商品");
});

Deno.test("a wardrobe try-on can be retried by its own id", () => {
  // deno-lint-ignore no-explicit-any
  const message = wardrobeTryonErrorMessage("generation", wardrobeItem) as any;
  const [retry] = message.quickReply.items;

  assertEquals(retry.action.type, "postback");
  assertEquals(retry.action.data, wardrobeTryonPostbackData(wardrobeItem.id));
  assertEquals(retry.action.displayText, "試穿「你的上衣」");
});

Deno.test("a busy service offers no button to press", () => {
  // deno-lint-ignore no-explicit-any
  const message = wardrobeTryonErrorMessage("busy", wardrobeItem) as any;
  assertEquals(message.quickReply, undefined);
});
