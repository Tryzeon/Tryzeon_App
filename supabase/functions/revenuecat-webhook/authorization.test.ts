import { assertEquals } from "@std/assert";
import { isAuthorized } from "./authorization.ts";

const SECRET = "s3cr3t!value";

Deno.test("a bare secret is accepted", () => {
  assertEquals(isAuthorized(SECRET, SECRET), true);
});

Deno.test("a Bearer-prefixed secret is accepted", () => {
  assertEquals(isAuthorized(`Bearer ${SECRET}`, SECRET), true);
});

Deno.test("a missing header is rejected", () => {
  assertEquals(isAuthorized(null, SECRET), false);
});

Deno.test("a wrong secret is rejected", () => {
  assertEquals(isAuthorized("Bearer s3cr3t", SECRET), false);
});
