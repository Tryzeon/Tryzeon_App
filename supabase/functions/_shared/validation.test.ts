import { assertEquals, assertThrows } from "jsr:@std/assert";
import { normalizeText, requireString, ValidationError } from "./validation.ts";

Deno.test("requireString rejects missing and empty values", () => {
  assertEquals(requireString("ok", "field"), "ok");
  assertThrows(() => requireString("", "field"), ValidationError, "field");
  assertThrows(() => requireString(undefined, "field"), ValidationError);
  assertThrows(() => requireString(42, "field"), ValidationError);
});

Deno.test("normalizeText trims, blanks to undefined, and never truncates", () => {
  assertEquals(normalizeText("  hi  "), "hi");
  assertEquals(normalizeText("   "), undefined);
  assertEquals(normalizeText(undefined), undefined);
  assertEquals(normalizeText(42), undefined);
  const long = "x".repeat(5000);
  assertEquals(normalizeText(long)?.length, 5000);
});
