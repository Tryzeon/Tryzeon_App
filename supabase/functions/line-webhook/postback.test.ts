import { assertEquals } from "jsr:@std/assert";
import {
  parsePostback,
  productTryonPostbackData,
  wardrobeTryonPostbackData,
} from "./postback.ts";

const PID = "8f14e45f-ceea-467a-9c8d-1b2c3d4e5f60";
const WID = "44444444-4444-4444-4444-444444444444";

Deno.test("what a product card encodes is what the webhook reads back", () => {
  assertEquals(parsePostback(productTryonPostbackData(PID)), {
    kind: "product",
    productId: PID,
  });
});

Deno.test("what a wardrobe card encodes is what the webhook reads back", () => {
  assertEquals(parsePostback(wardrobeTryonPostbackData(WID)), {
    kind: "wardrobe",
    wardrobeItemId: WID,
  });
});

Deno.test("the two kinds cannot be mistaken for each other", () => {
  // Each action reads only its own id parameter, so a payload carrying the
  // other kind's parameter names nothing.
  assertEquals(parsePostback(`a=tryon_product&wid=${WID}`), null);
  assertEquals(parsePostback(`a=tryon_wardrobe&pid=${PID}`), null);
});

Deno.test("a card from before the rename no longer resolves", () => {
  // Deliberate: back-compat was declined, so cards already sent stop working
  // and fall through to the hint. Written as a test so the decision is
  // recorded rather than rediscovered.
  assertEquals(parsePostback(`a=tryon&pid=${PID}`), null);
});

Deno.test("an unknown action is not ours to handle", () => {
  assertEquals(parsePostback(`a=save&pid=${PID}`), null);
  assertEquals(parsePostback(`pid=${PID}`), null);
  assertEquals(parsePostback(""), null);
});

Deno.test("an id Postgres would reject never reaches Postgres", () => {
  assertEquals(parsePostback("a=tryon_product&pid=not-a-uuid"), null);
  assertEquals(parsePostback("a=tryon_product&pid="), null);
  assertEquals(parsePostback("a=tryon_product"), null);
  assertEquals(parsePostback("a=tryon_wardrobe&wid=not-a-uuid"), null);
  assertEquals(parsePostback("a=tryon_wardrobe&wid="), null);
  assertEquals(parsePostback("a=tryon_wardrobe"), null);
});

Deno.test("a data field that is not even a string is not a postback", () => {
  assertEquals(parsePostback(undefined), null);
  assertEquals(parsePostback(null), null);
  assertEquals(parsePostback({ a: "tryon_product" }), null);
});
