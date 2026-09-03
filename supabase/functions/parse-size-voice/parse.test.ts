import { assertEquals } from "jsr:@std/assert@^1.0.19";
import { normalizeParsedSizes, normalizeSizeName } from "./parse.ts";

Deno.test("normalizeSizeName maps aliases onto the canonical literal", () => {
  assertEquals(normalizeSizeName("XXL"), "2XL");
  assertEquals(normalizeSizeName("xxl"), "2XL");
  assertEquals(normalizeSizeName("均碼"), "均碼");
  assertEquals(normalizeSizeName("one size"), "均碼");
  assertEquals(normalizeSizeName("Medium"), "M");
  assertEquals(normalizeSizeName("1XL"), "XL");
});

Deno.test("normalizeSizeName trims and upper-cases a standard label", () => {
  assertEquals(normalizeSizeName(" m "), "M");
  assertEquals(normalizeSizeName("2xl"), "2XL");
});

Deno.test("normalizeSizeName keeps an unrecognised name as spoken", () => {
  assertEquals(normalizeSizeName("US 10"), "US 10");
  assertEquals(normalizeSizeName("4XL"), "4XL");
  assertEquals(normalizeSizeName(" 加大 "), "加大");
  assertEquals(normalizeSizeName(""), "");
});

Deno.test("normalizeParsedSizes keeps thigh_circumference", () => {
  const parsed = normalizeParsedSizes({
    sizes: [
      {
        name: "L",
        measurements: { thigh_circumference: { value: 60, unit: "centimeter" } },
      },
    ],
  });
  assertEquals(parsed[0].measurements.thigh_circumference, {
    value: 60,
    unit: "centimeter",
  });
});

Deno.test("normalizeParsedSizes normalizes the name it returns", () => {
  const parsed = normalizeParsedSizes({
    sizes: [
      { name: "XXL", measurements: { chest_circumference: { value: 100, unit: "centimeter" } } },
      { name: "US 10", measurements: {} },
    ],
  });
  assertEquals(parsed.map((s) => s.name), ["2XL", "US 10"]);
  assertEquals(parsed[0].measurements.chest_circumference, { value: 100, unit: "centimeter" });
});
