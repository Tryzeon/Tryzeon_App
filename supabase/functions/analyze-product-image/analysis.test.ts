import { assertEquals } from "@std/assert";
import { buildPrompt, buildSchema, toResponse } from "./analysis.ts";

const CATEGORIES = new Map([["襯衫", "cat-shirt"], ["褲子", "cat-pants"]]);
const CATEGORY_NAMES = [...CATEGORIES.keys()];

type PropertySpec = { type: string; enum?: string[]; items?: { enum?: string[] } };

const schemaProperties = (): Record<string, PropertySpec> =>
  (buildSchema(CATEGORY_NAMES) as { properties: Record<string, PropertySpec> }).properties;

const acceptedValues = (spec: PropertySpec): string[] => spec.enum ?? spec.items?.enum ?? [];

const fullAnswer = {
  name: "白色寬鬆棉質襯衫",
  category: "襯衫",
  gender: "female",
  styles: ["korean", "minimalist"],
  seasons: ["spring", "summer"],
  material: "棉",
  fit: "loose",
  thickness: "low",
  elasticity: "none",
};

Deno.test("toResponse passes a fully answered analysis through", () => {
  assertEquals(toResponse(fullAnswer, CATEGORIES), {
    name: "白色寬鬆棉質襯衫",
    categoryId: "cat-shirt",
    gender: "female",
    styles: ["korean", "minimalist"],
    seasons: ["spring", "summer"],
    material: "棉",
    fit: "loose",
    thickness: "low",
    elasticity: "none",
  });
});

Deno.test("toResponse maps the unknown sentinel to null on every field", () => {
  const unknowns = Object.fromEntries(
    Object.keys(fullAnswer).map((k) => [k, "unknown"]),
  );
  const result = toResponse({ ...unknowns, styles: [], seasons: [] }, CATEGORIES);

  assertEquals(result, {
    name: null,
    categoryId: null,
    gender: null,
    styles: [],
    seasons: [],
    material: null,
    fit: null,
    thickness: null,
    elasticity: null,
  });
});

// The bug this guards: `name` is the one field the schema can't restrict to an
// enum, so a model that can't name the product used to answer with the literal
// string "null" — which reached the form and showed up as the word "null" in
// the product-name input. The prompt now teaches `unknown` instead.
Deno.test("toResponse drops an unanswered name", () => {
  for (const noAnswer of ["unknown", "UNKNOWN", "  "]) {
    assertEquals(
      toResponse({ ...fullAnswer, name: noAnswer }, CATEGORIES).name,
      null,
      `expected ${JSON.stringify(noAnswer)} to be rejected as a name`,
    );
  }
});

Deno.test("toResponse drops a material outside the preset list", () => {
  for (const offList of ["unknown", "cotton", "棉質", "牛仔"]) {
    assertEquals(
      toResponse({ ...fullAnswer, material: offList }, CATEGORIES).material,
      null,
      `expected ${JSON.stringify(offList)} to be rejected as a material`,
    );
  }
});

Deno.test("toResponse treats missing fields as unanswered", () => {
  assertEquals(toResponse({}, CATEGORIES), {
    name: null,
    categoryId: null,
    gender: null,
    styles: [],
    seasons: [],
    material: null,
    fit: null,
    thickness: null,
    elasticity: null,
  });
});

Deno.test("toResponse truncates an over-long name to 20 characters", () => {
  const long = "白".repeat(30);
  assertEquals(toResponse({ ...fullAnswer, name: long }, CATEGORIES).name, "白".repeat(20));
});

Deno.test("toResponse caps styles at 3 and drops duplicates and unknown values", () => {
  const result = toResponse({
    ...fullAnswer,
    styles: ["korean", "korean", "minimalist", "casual", "sporty", "not-a-style"],
  }, CATEGORIES);
  assertEquals(result.styles, ["korean", "minimalist", "casual"]);
});

Deno.test("toResponse nulls a category name that no longer exists", () => {
  assertEquals(toResponse({ ...fullAnswer, category: "外套" }, CATEGORIES).categoryId, null);
});

// These two lock the prompt and the schema to one vocabulary: teaching `null`
// while the schema has no way to accept it is how the model came to answer with
// the *word*.
Deno.test("buildPrompt teaches the sentinel the schema accepts", () => {
  const props = schemaProperties();
  const enums = Object.values(props)
    .map((spec) => spec.enum)
    .filter((e): e is string[] => e != null);
  const shared = enums.reduce((acc, e) => acc.filter((v) => e.includes(v)));
  assertEquals(shared.length, 1, "expected exactly one sentinel common to all enums");

  // Once per field that can go unanswered, plus the rule stated up front.
  const unanswerable = Object.values(props).filter((s) => s.type !== "array").length;
  const prompt = buildPrompt(CATEGORY_NAMES);
  assertEquals(prompt.split(shared[0]).length - 1, unanswerable + 1);
});

Deno.test("buildPrompt spells out every value the schema accepts", () => {
  const prompt = buildPrompt(CATEGORY_NAMES);
  for (const [field, spec] of Object.entries(schemaProperties())) {
    for (const value of acceptedValues(spec)) {
      assertEquals(prompt.includes(value), true, `prompt never offers ${field}=${value}`);
    }
  }
});

Deno.test("buildSchema requires every field and offers an unknown sentinel", () => {
  const props = schemaProperties();
  const fields = Object.keys(props);
  const required = (buildSchema(CATEGORY_NAMES) as { required: string[] }).required;

  assertEquals(required.sort(), fields.sort());

  // Without a legal way to say "I can't tell", the model invents a string.
  for (const [field, spec] of Object.entries(props)) {
    if (spec.type === "array" || field === "name") continue;
    assertEquals(
      spec.enum?.includes("unknown"),
      true,
      `expected ${field} to accept the unknown sentinel`,
    );
  }
});
