import { assertEquals } from "jsr:@std/assert";
import { renderAnswer } from "./chat-render.ts";
import type { LineProduct } from "./product-card.ts";

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

Deno.test("an empty answer degrades to text rather than an empty send", () => {
  const out = renderAnswer([]);
  assertEquals(out.length, 1);
  assertEquals((out[0] as { type: string }).type, "text");
});

Deno.test("every product card offers a try-on, keyed by its own id", () => {
  const out = renderAnswer([card(product("p1")), card(product("p2"))]);
  const [first, second] = bubbles(out[0]);

  assertEquals(first.footer.contents[0].action, {
    type: "postback",
    label: "試穿這件",
    data: "a=tryon&pid=p1",
    displayText: "試穿「商品 p1」",
  });
  assertEquals(second.footer.contents[0].action.data, "a=tryon&pid=p2");
});

Deno.test("the try-on button is filled and the purchase button is outlined", () => {
  const out = renderAnswer([
    card(product("p1", { purchaseUrl: "https://shop.example/p1" })),
  ]);
  const [{ footer }] = bubbles(out[0]);

  assertEquals(footer.contents.length, 2);
  assertEquals(footer.contents[0].backgroundColor, "#1A1A1A");
  assertEquals(footer.contents[0].cornerRadius, "8px");
  assertEquals(footer.contents[1].backgroundColor, undefined);
  assertEquals(footer.contents[1].borderWidth, "1px");
  assertEquals(footer.contents[1].action.uri, "https://shop.example/p1");
});

Deno.test("a product with no purchase link still gets its try-on button", () => {
  const out = renderAnswer([card(product("p1"))]);
  const [{ footer }] = bubbles(out[0]);

  assertEquals(footer.contents.length, 1);
  assertEquals(footer.contents[0].action.type, "postback");
});

Deno.test("a link LINE would reject is dropped, and takes nothing else with it", () => {
  const out = renderAnswer([card(product("p1", { purchaseUrl: "shop.example/p1" }))]);
  const [{ footer }] = bubbles(out[0]);

  assertEquals(footer.contents.length, 1);
  assertEquals(footer.contents[0].action.type, "postback");
});

Deno.test("an over-long product name is clamped in the postback displayText", () => {
  // `displayText` fails the whole send past 300 characters, and a product
  // name carries no length constraint of its own.
  const longName = "衣".repeat(60);
  const out = renderAnswer([card(product("p1", { name: longName }))]);
  const [{ footer }] = bubbles(out[0]);

  const displayText = footer.contents[0].action.displayText as string;
  assertEquals(displayText.length <= 300, true);
  assertEquals(displayText, `試穿「${"衣".repeat(40)}…」`);
});

Deno.test("the card pins its own surface, so no theme can dim the type", () => {
  const [bubble] = bubbles(renderAnswer([card(product("p1"))])[0]);

  assertEquals(bubble.styles.body.backgroundColor, "#FFFFFF");
  assertEquals(bubble.styles.footer.backgroundColor, "#FFFFFF");
});

Deno.test("the body and footer sit on the 8px grid, and do not double up", () => {
  const [bubble] = bubbles(renderAnswer([card(product("p1"))])[0]);

  assertEquals(bubble.body.paddingAll, "16px");
  assertEquals(bubble.footer.paddingAll, "16px");
  // Without this the body's bottom padding and the footer's top padding stack
  // into a 32px gap, which is too much air for a kilo card.
  assertEquals(bubble.footer.paddingTop, "0px");
});
