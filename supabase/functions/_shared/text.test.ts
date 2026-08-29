import { assertEquals } from "jsr:@std/assert";
import { isUuid, nonEmptyStr, textArrayValues } from "./text.ts";

Deno.test("nonEmptyStr trims, and rejects blanks and non-strings", () => {
  assertEquals(nonEmptyStr("  白襯衫 "), "白襯衫");
  assertEquals(nonEmptyStr("   "), null);
  assertEquals(nonEmptyStr(""), null);
  assertEquals(nonEmptyStr(42), null);
  assertEquals(nonEmptyStr(null), null);
});

Deno.test("textArrayValues drops the elements a text[] column can hold but its type denies", () => {
  // `supabase gen types` emits `string[]` for a `text[]` column; Postgres lets
  // that array hold NULLs, so this is the gap between the two.
  assertEquals(textArrayValues(["a", null, 7, "b"]), ["a", "b"]);
  assertEquals(textArrayValues([]), []);
  assertEquals(textArrayValues(null), []);
  assertEquals(textArrayValues(undefined), []);
});

Deno.test("isUuid accepts a canonical uuid in either case", () => {
  assertEquals(isUuid("8f14e45f-ceea-467a-9c8d-1b2c3d4e5f60"), true);
  assertEquals(isUuid("8F14E45F-CEEA-467A-9C8D-1B2C3D4E5F60"), true);
});

Deno.test("isUuid rejects anything Postgres would choke on", () => {
  assertEquals(isUuid(""), false);
  assertEquals(isUuid("not-a-uuid"), false);
  // 沒有連字號的 32 位十六進位字串：Postgres 收，但我們的 id 不長這樣
  assertEquals(isUuid("8f14e45fceea467a9c8d1b2c3d4e5f60"), false);
  // 多一段
  assertEquals(isUuid("8f14e45f-ceea-467a-9c8d-1b2c3d4e5f60-extra"), false);
  // 混入非十六進位字元
  assertEquals(isUuid("8f14e45f-ceea-467a-9c8d-1b2c3d4e5g60"), false);
});
