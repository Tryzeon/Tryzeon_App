import { assertEquals, assertThrows } from "jsr:@std/assert";
import { parseLiffTryonBody } from "./request.ts";
import { ValidationError } from "../_shared/tryon/index.ts";

const valid = {
  idToken: "tok",
  productId: "11111111-1111-1111-1111-111111111111",
};

Deno.test("parseLiffTryonBody decodes a complete body", () => {
  assertEquals(parseLiffTryonBody(JSON.stringify(valid)), valid);
});

Deno.test("parseLiffTryonBody ignores a legacy avatarBase64 field", () => {
  // The old client sent the photo inline; the avatar now comes from the user's
  // profile, so an extra field must not fail the request during the rollout.
  const legacy = { ...valid, avatarBase64: "AAAA" };
  assertEquals(parseLiffTryonBody(JSON.stringify(legacy)), valid);
});

Deno.test("parseLiffTryonBody rejects unparseable JSON as a validation error", () => {
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
  for (const field of ["idToken", "productId"] as const) {
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
