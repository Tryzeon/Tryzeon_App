import { assertEquals, assertThrows } from "jsr:@std/assert@^1.0.19";
import { parseLineAuthBody } from "./request.ts";
import { ValidationError } from "../_shared/validation.ts";

const valid = { idToken: "tok" };
const decoded = { idToken: "tok", nonce: undefined };

Deno.test("parseLineAuthBody decodes a complete body", () => {
  assertEquals(parseLineAuthBody(JSON.stringify(valid)), decoded);
});

Deno.test("parseLineAuthBody keeps a supplied nonce", () => {
  assertEquals(
    parseLineAuthBody(JSON.stringify({ ...valid, nonce: "n1" })),
    { idToken: "tok", nonce: "n1" },
  );
});

Deno.test("parseLineAuthBody drops every field but idToken and nonce", () => {
  // The security invariant: a caller-supplied email must never reach
  // `generateLink`, which would create an account for it rather than failing.
  const hostile = { ...valid, email: "victim@example.com", userId: "other-user" };
  assertEquals(parseLineAuthBody(JSON.stringify(hostile)), decoded);
});

Deno.test("parseLineAuthBody rejects unparseable JSON as a validation error", () => {
  assertThrows(() => parseLineAuthBody("{not json"), ValidationError, "valid JSON");
});

Deno.test("parseLineAuthBody rejects a non-object body", () => {
  assertThrows(() => parseLineAuthBody("null"), ValidationError, "object");
  assertThrows(() => parseLineAuthBody("[]"), ValidationError);
});

Deno.test("parseLineAuthBody names the missing field", () => {
  assertThrows(
    () => parseLineAuthBody(JSON.stringify({ idToken: "" })),
    ValidationError,
    "idToken",
  );
});

Deno.test("parseLineAuthBody rejects a non-string idToken", () => {
  assertThrows(
    () => parseLineAuthBody(JSON.stringify({ idToken: 42 })),
    ValidationError,
    "idToken",
  );
});
