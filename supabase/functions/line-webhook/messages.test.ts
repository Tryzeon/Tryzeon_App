import { assertEquals } from "jsr:@std/assert";
import {
  chatErrorMessage,
  onboardingMessage,
  productTryonErrorMessage,
  tryonErrorMessage,
} from "./messages.ts";
import type { LineProduct } from "./product-card.ts";

const PID = "8f14e45f-ceea-467a-9c8d-1b2c3d4e5f60";

const product: LineProduct = {
  id: PID,
  name: "短版牛仔外套",
  price: 1280,
  imageUrl: "https://img.example/stores/s1/p1.jpg",
  storeName: "某店",
  purchaseUrl: null,
};

/**
 * The full actions a message's chips carry, in order.
 *
 * Full objects, not labels alone: a `message` chip's `text` is what lands in
 * the chat as though the sender typed it, so a test that only reads `label`
 * would let it drift from what the button promises without failing.
 */
const chipActions = (message: object): object[] =>
  // deno-lint-ignore no-explicit-any
  ((message as { quickReply?: { items: any[] } }).quickReply?.items ?? []).map(
    (i) => i.action,
  );

/** The template's own button, which is not a chip. */
const templateUri = (message: object): string =>
  (message as { template: { actions: { uri: string }[] } }).template.actions[0].uri;

Deno.test("onboarding reaches both liff-web screens from one base URL", () => {
  // The paths belong to us (`liff-web/src/router.tsx`), so only the LIFF app's
  // own URL is configuration. The catalog chip is the escape hatch for someone
  // not ready to upload a photo of themselves: they can go look before leaving.
  const message = onboardingMessage("https://liff.example");

  assertEquals(templateUri(message), "https://liff.example/onboard");
  assertEquals(chipActions(message), [
    { type: "uri", label: "先逛逛商品", uri: "https://liff.example" },
    { type: "message", label: "這是什麼服務", text: "你是誰，你能幫我做什麼" },
  ]);
});

Deno.test("a base URL with a trailing slash does not double up", () => {
  // LINE rejects a malformed uri by failing the whole send, not the one action,
  // so `LIFF_URL` written either way has to produce the same link.
  assertEquals(
    templateUri(onboardingMessage("https://liff.example/")),
    "https://liff.example/onboard",
  );
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
  // Regression for the mismatch this chip once had: the label promised to
  // re-ask the question that just failed, but the text it typed on the
  // sender's behalf was an unrelated generic request. Label and text must
  // both read as the same offer.
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
  // One string naming both remedies, rather than a per-path split. It has to
  // stay that way deliberately: the two paths can act on different halves of it
  // — a photo cannot usefully be retried as-is, a catalog product can — so if
  // this ever needs to say only one of them, it needs two strings again.
  const text = "這件沒能生成，請換一件或再試一次看看！";

  assertEquals((tryonErrorMessage("generation") as { text: string }).text, text);
  assertEquals(
    (productTryonErrorMessage("generation", product) as { text: string }).text,
    text,
  );
});

Deno.test("a spent try-on quota on the product path offers the chat the sender still has", () => {
  assertEquals(chipActions(productTryonErrorMessage("quota", product)), [
    { type: "message", label: "找衣服看看", text: "有什麼推薦的商品" },
  ]);
});

Deno.test("a product that would not generate is retried by id, not by a message chip", () => {
  // No `tryonNote` is written on this path, so a `message` chip asking for
  // "類似的" would have nothing behind it. The retry carries the product id
  // itself instead.
  assertEquals(chipActions(productTryonErrorMessage("generation", product)), [
    {
      type: "postback",
      label: "再試一次",
      data: `a=tryon&pid=${PID}`,
      displayText: "試穿「短版牛仔外套」",
    },
  ]);
});

Deno.test("an unknown product try-on failure is also retried by id", () => {
  assertEquals(chipActions(productTryonErrorMessage("unknown", product)), [
    {
      type: "postback",
      label: "再試一次",
      data: `a=tryon&pid=${PID}`,
      displayText: "試穿「短版牛仔外套」",
    },
  ]);
});
