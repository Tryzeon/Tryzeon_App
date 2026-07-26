import { assertEquals, assertThrows } from "jsr:@std/assert";
import { parseLiffTryonBody } from "./request.ts";
import { ValidationError } from "../_shared/tryon/index.ts";

const valid = {
  idToken: "tok",
  avatarBase64: "AAAA",
  productId: "11111111-1111-1111-1111-111111111111",
};

Deno.test("parseLiffTryonBody decodes a complete body", () => {
  assertEquals(parseLiffTryonBody(JSON.stringify(valid)), valid);
});

Deno.test("parseLiffTryonBody rejects unparseable JSON as a validation error", () => {
  // Previously this escaped as a SyntaxError and surfaced as a 500; owning
  // JSON.parse here makes a malformed body a 400 like every other bad request.
  assertThrows(
    () => parseLiffTryonBody("{not json"),
    ValidationError,
    "valid JSON",
  );
});

Deno.test("parseLiffTryonBody rejects a non-object body", () => {
  assertThrows(() => parseLiffTryonBody("null"), ValidationError, "object");
  assertThrows(() => parseLiffTryonBody("[]"), ValidationError);
});

Deno.test("parseLiffTryonBody names the missing field", () => {
  for (const field of ["idToken", "avatarBase64", "productId"] as const) {
    const body = { ...valid, [field]: "" };
    assertThrows(
      () => parseLiffTryonBody(JSON.stringify(body)),
      ValidationError,
      field,
    );
  }
});

Deno.test("parseLiffTryonBody rejects a non-string field", () => {
  assertThrows(
    () => parseLiffTryonBody(JSON.stringify({ ...valid, productId: 42 })),
    ValidationError,
    "productId",
  );
});
