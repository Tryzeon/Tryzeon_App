import { assertEquals } from "jsr:@std/assert";
import {
  mapSearchProductsArgs,
  parseAnswerRefs,
  toModelMessages,
} from "./logic.ts";

Deno.test("mapSearchProductsArgs trims query, keeps non-empty arrays, drops empties", () => {
  const p = mapSearchProductsArgs(
    { query: "  白襯衫 ", styles: ["casual"], materials: [], min_price: 100, gender: "female" },
    { categoryIds: ["c1"], limit: 8 },
  );
  assertEquals(p.p_search_query, "白襯衫");
  assertEquals(p.p_styles, ["casual"]);
  assertEquals(p.p_materials, null);
  assertEquals(p.p_min_price, 100);
  assertEquals(p.p_category_ids, ["c1"]);
  assertEquals(p.p_gender, "female");
  assertEquals(p.p_limit, 8);
});

Deno.test("mapSearchProductsArgs defaults: null query, limit 10, null gender", () => {
  const p = mapSearchProductsArgs({}, { categoryIds: null });
  assertEquals(p.p_search_query, null);
  assertEquals(p.p_category_ids, null);
  assertEquals(p.p_gender, null);
  assertEquals(p.p_limit, 10);
});

Deno.test("parseAnswerRefs keeps ordered text + labelled product/wardrobe ids", () => {
  const refs = parseAnswerRefs({
    blocks: [
      { type: "text", text: "上身白襯衫" },
      { type: "product", id: "p-1" },
      { type: "wardrobe", id: "w-2" },
    ],
  });
  assertEquals(refs, [
    { type: "text", text: "上身白襯衫" },
    { type: "product", id: "p-1" },
    { type: "wardrobe", id: "w-2" },
  ]);
});

Deno.test("parseAnswerRefs drops empty text and id-less product/wardrobe blocks", () => {
  const refs = parseAnswerRefs({
    blocks: [
      { type: "text", text: "   " },
      { type: "product" },
      { type: "wardrobe", id: "" },
      { type: "product", id: "p-1" },
    ],
  });
  assertEquals(refs, [{ type: "product", id: "p-1" }]);
});

Deno.test("toModelMessages maps a paired tool_use/tool_result conversation to ModelMessages", () => {
  const out = toModelMessages([
    { role: "user", content: [{ type: "text", text: "找裙子" }] },
    {
      role: "assistant",
      content: [{ type: "tool_use", id: "tu_0", name: "search_products", input: { query: "裙" } }],
    },
    {
      role: "user",
      content: [{ type: "tool_result", tool_use_id: "tu_0", content: { items: [{ id: "p1" }] } }],
    },
    { role: "assistant", content: [{ type: "text", text: "找到這件" }, { type: "product", id: "p1" }] },
  ]);
  assertEquals(out, [
    { role: "user", content: "找裙子" },
    {
      role: "assistant",
      content: [{ type: "tool-call", toolCallId: "tu_0", toolName: "search_products", input: { query: "裙" } }],
    },
    {
      role: "tool",
      content: [{
        type: "tool-result",
        toolCallId: "tu_0",
        toolName: "search_products",
        output: { type: "json", value: { items: [{ id: "p1" }] } },
      }],
    },
    { role: "assistant", content: "找到這件\n（推薦商品 id:p1）" },
  ]);
});

Deno.test("toModelMessages drops blank text and empty turns", () => {
  const out = toModelMessages([
    { role: "user", content: [{ type: "text", text: "   " }] },
    { role: "assistant", content: [{ type: "text", text: "嗨" }] },
  ]);
  assertEquals(out, [{ role: "assistant", content: "嗨" }]);
});
