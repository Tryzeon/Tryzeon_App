import { assertEquals, assertThrows } from "jsr:@std/assert";
import { parseLiffTryonBody, ValidationError } from "./request.ts";

Deno.test("parseLiffTryonBody accepts a complete body", () => {
  const out = parseLiffTryonBody({ idToken: "t", avatarBase64: "a", productId: "p" });
  assertEquals(out, { idToken: "t", avatarBase64: "a", productId: "p" });
});

Deno.test("parseLiffTryonBody rejects missing idToken", () => {
  assertThrows(() => parseLiffTryonBody({ avatarBase64: "a", productId: "p" }), ValidationError);
});

Deno.test("parseLiffTryonBody rejects empty avatarBase64", () => {
  assertThrows(() => parseLiffTryonBody({ idToken: "t", avatarBase64: "", productId: "p" }), ValidationError);
});

Deno.test("parseLiffTryonBody rejects missing productId", () => {
  assertThrows(() => parseLiffTryonBody({ idToken: "t", avatarBase64: "a" }), ValidationError);
});

Deno.test("parseLiffTryonBody rejects non-object body", () => {
  assertThrows(() => parseLiffTryonBody(null), ValidationError);
});
