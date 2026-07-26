import { assertEquals } from "jsr:@std/assert";
import { renderAnswer } from "./chat-render.ts";
import type { LineProduct } from "./chat-hydrate.ts";

const product = (id: string, over: Partial<LineProduct> = {}): LineProduct => ({
  id,
  name: `商品 ${id}`,
  price: 1200,
  imageUrl: `https://img.example/${id}.jpg`,
  storeName: "某店",
  purchaseUrl: null,
  ...over,
});

const text = (t: string) => ({ type: "text", text: t });
const card = (p: LineProduct) => ({ type: "product", item: p });

// deno-lint-ignore no-explicit-any
const bubbles = (message: any) => message.contents.contents as any[];

Deno.test("a text-only answer is a single text message", () => {
  const out = renderAnswer([text("你想找什麼樣的衣服？")]);
  assertEquals(out, [{ type: "text", text: "你想找什麼樣的衣服？" }]);
});

Deno.test("consecutive products collapse into one carousel", () => {
  const out = renderAnswer([
    text("為你找到這幾件"),
    card(product("p1")),
    card(product("p2")),
  ]);

  assertEquals(out.length, 2);
  assertEquals(out[0], { type: "text", text: "為你找到這幾件" });
  assertEquals(bubbles(out[1]).length, 2);
});

Deno.test("adjacent text blocks merge into one message", () => {
  const out = renderAnswer([text("第一句"), text("第二句"), card(product("p1"))]);

  assertEquals(out.length, 2);
  assertEquals(out[0], { type: "text", text: "第一句\n第二句" });
});

Deno.test("a two-part outfit keeps its interleaving", () => {
  const out = renderAnswer([
    text("上身"),
    card(product("p1")),
    text("下身"),
    card(product("p2")),
  ]);

  assertEquals(out.length, 4);
  assertEquals(out.map((m) => (m as { type: string }).type), [
    "text",
    "flex",
    "text",
    "flex",
  ]);
});

Deno.test("more sections than LINE allows fold into prose plus one carousel", () => {
  const out = renderAnswer([
    text("上身"),
    card(product("p1")),
    text("下身"),
    card(product("p2")),
    text("外套"),
    card(product("p3")),
  ]);

  assertEquals(out.length, 2);
  assertEquals(out[0], { type: "text", text: "上身\n下身\n外套" });
  // Order is preserved through the fold, and nothing is dropped.
  assertEquals(bubbles(out[1]).map((b) => b.body.contents[0].text), [
    "商品 p1",
    "商品 p2",
    "商品 p3",
  ]);
});

Deno.test("a run longer than one carousel splits rather than truncates", () => {
  const items = Array.from({ length: 15 }, (_, i) => card(product(`p${i}`)));
  const out = renderAnswer(items);

  assertEquals(out.length, 2);
  assertEquals(bubbles(out[0]).length, 12);
  assertEquals(bubbles(out[1]).length, 3);
});

Deno.test("a product with a purchase link gets a button, one without gets none", () => {
  const out = renderAnswer([
    card(product("p1", { purchaseUrl: "https://shop.example/p1" })),
    card(product("p2")),
  ]);

  const [withLink, withoutLink] = bubbles(out[0]);
  assertEquals(withLink.footer.contents[0].action.uri, "https://shop.example/p1");
  assertEquals(withoutLink.footer, undefined);
});

Deno.test("a link LINE would reject is not offered as an action", () => {
  const out = renderAnswer([card(product("p1", { purchaseUrl: "shop.example/p1" }))]);
  assertEquals(bubbles(out[0])[0].footer, undefined);
});

Deno.test("an empty answer degrades to text rather than an empty send", () => {
  const out = renderAnswer([]);
  assertEquals(out.length, 1);
  assertEquals((out[0] as { type: string }).type, "text");
});
