import { assertEquals } from "jsr:@std/assert";
import { ANALYSIS_PROMPT, ANALYSIS_SCHEMA, toResponse } from "./analysis.ts";

type PropertySpec = { type: string; enum?: string[] };

const schemaProperties = (): Record<string, PropertySpec> =>
  (ANALYSIS_SCHEMA as { properties: Record<string, PropertySpec> }).properties;

Deno.test("toResponse passes a valid category through", () => {
  assertEquals(toResponse({ category: "bottoms", tags: [] }).category, "bottoms");
});

Deno.test("toResponse maps the unknown sentinel to null", () => {
  assertEquals(toResponse({ category: "unknown", tags: [] }).category, null);
});

Deno.test("toResponse nulls a category outside the list", () => {
  assertEquals(toResponse({ category: "shoes", tags: [] }).category, null);
});

Deno.test("toResponse nulls a non-string or missing category", () => {
  assertEquals(toResponse({ category: 3, tags: [] }).category, null);
  assertEquals(toResponse({ tags: [] }).category, null);
});

Deno.test("toResponse drops tags that are not non-empty strings", () => {
  assertEquals(
    toResponse({ category: "top", tags: ["藍", "", 7, null, "棉"] }).tags,
    ["藍", "棉"],
  );
});

Deno.test("toResponse caps tags at the stated maximum", () => {
  const overLong = ["黑", "白", "灰", "米", "棕", "紅", "橙", "黃"];
  assertEquals(toResponse({ category: "top", tags: overLong }).tags, [
    "黑",
    "白",
    "灰",
    "米",
    "棕",
    "紅",
  ]);
});

Deno.test("toResponse treats a non-array tags field as empty", () => {
  assertEquals(toResponse({ category: "top", tags: "藍" }).tags, []);
  assertEquals(toResponse({ category: "top" }).tags, []);
});

Deno.test("toResponse passes a fully valid answer through", () => {
  assertEquals(toResponse({ category: "outerwear", tags: ["黑", "皮革"] }), {
    category: "outerwear",
    tags: ["黑", "皮革"],
  });
});

Deno.test("toResponse keeps duplicate tags — the app does not expect them collapsed", () => {
  assertEquals(toResponse({ category: "top", tags: ["黑", "黑"] }).tags, ["黑", "黑"]);
});

// Locked so a future pass at parity with the sibling module doesn't add
// `.trim()` unnoticed.
Deno.test("toResponse does not trim tags", () => {
  assertEquals(toResponse({ category: "top", tags: [" 黑 "] }).tags, [" 黑 "]);
});

// The three below lock the prompt, the schema and the sanitiser to one
// vocabulary: change one and these fail rather than the model quietly answering
// with a word nothing accepts.
Deno.test("ANALYSIS_PROMPT offers every category the schema accepts", () => {
  for (const value of schemaProperties().category.enum ?? []) {
    assertEquals(
      ANALYSIS_PROMPT.includes(value),
      true,
      `prompt never offers category=${value}`,
    );
  }
});

Deno.test("ANALYSIS_PROMPT teaches the one category the sanitiser rejects", () => {
  const accepted = schemaProperties().category.enum ?? [];
  const sentinels = accepted.filter(
    (v) => toResponse({ category: v, tags: [] }).category === null,
  );
  assertEquals(
    sentinels.length,
    1,
    "expected exactly one value the schema offers and the sanitiser strips",
  );
  assertEquals(ANALYSIS_PROMPT.includes(sentinels[0]), true);
});

Deno.test("ANALYSIS_PROMPT states the tag cap the sanitiser enforces", () => {
  const many = Array.from({ length: 20 }, (_, i) => `t${i}`);
  const cap = toResponse({ category: "top", tags: many }).tags.length;
  assertEquals(
    ANALYSIS_PROMPT.includes(`最多 ${cap} 個`),
    true,
    `prompt does not state the ${cap}-tag cap the sanitiser enforces`,
  );
});

Deno.test("ANALYSIS_SCHEMA requires every field it declares", () => {
  const required = (ANALYSIS_SCHEMA as { required: string[] }).required;
  assertEquals([...required].sort(), Object.keys(schemaProperties()).sort());
});
