import { assertEquals } from "@std/assert";
import { isUuid, nonEmptyStr, textArrayValues } from "./text.ts";

Deno.test("nonEmptyStr trims, and rejects blanks and non-strings", () => {
  assertEquals(nonEmptyStr("  白襯衫 "), "白襯衫");
  assertEquals(nonEmptyStr("   "), null);
  assertEquals(nonEmptyStr(""), null);
  assertEquals(nonEmptyStr(42), null);
  assertEquals(nonEmptyStr(null), null);
});

Deno.test("textArrayValues drops the elements a text[] column can hold but its type denies", () => {
  assertEquals(textArrayValues(["a", null, 7, "b"]), ["a", "b"]);
  assertEquals(textArrayValues([]), []);
  assertEquals(textArrayValues(null), []);
  assertEquals(textArrayValues(undefined), []);
  assertEquals(textArrayValues("a" as unknown as readonly unknown[]), []);
});

Deno.test("isUuid accepts a canonical uuid in either case", () => {
  assertEquals(isUuid("8f14e45f-ceea-467a-9c8d-1b2c3d4e5f60"), true);
  assertEquals(isUuid("8F14E45F-CEEA-467A-9C8D-1B2C3D4E5F60"), true);
});

Deno.test("isUuid rejects anything Postgres would choke on", () => {
  assertEquals(isUuid(""), false);
  assertEquals(isUuid("not-a-uuid"), false);
  // A 32-digit hex string with no hyphens: Postgres accepts it, but our ids do
  // not look like that
  assertEquals(isUuid("8f14e45fceea467a9c8d1b2c3d4e5f60"), false);
  assertEquals(isUuid("8f14e45f-ceea-467a-9c8d-1b2c3d4e5f60-extra"), false);
  assertEquals(isUuid("8f14e45f-ceea-467a-9c8d-1b2c3d4e5g60"), false);
});
