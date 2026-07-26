import { assertEquals, assertThrows } from "jsr:@std/assert";
import {
  normalizeText,
  requireImageSource,
  requireString,
  validateTryonParams,
} from "./validate.ts";
import { ValidationError } from "./errors.ts";
import { LIMITS, type TryonParams } from "./types.ts";

const validParams: TryonParams = {
  userId: "u1",
  avatar: { base64: "AAAA" },
  garments: [{ images: [{ base64: "BBBB" }] }],
  mode: "image",
};

Deno.test("validateTryonParams accepts valid params", () => {
  validateTryonParams(validParams); // does not throw
});

Deno.test("validateTryonParams rejects an empty userId", () => {
  assertThrows(
    () => validateTryonParams({ ...validParams, userId: "" }),
    ValidationError,
    "userId",
  );
});

Deno.test("validateTryonParams rejects empty garments", () => {
  assertThrows(
    () => validateTryonParams({ ...validParams, garments: [] }),
    ValidationError,
  );
});

Deno.test("validateTryonParams rejects too many garments", () => {
  const g = { images: [{ base64: "X" }] };
  assertThrows(
    () => validateTryonParams({ ...validParams, garments: [g, g, g, g] }),
    ValidationError,
  );
});

Deno.test("validateTryonParams rejects too many images in a garment", () => {
  assertThrows(
    () =>
      validateTryonParams({
        ...validParams,
        garments: [{
          images: [{ base64: "1" }, { base64: "2" }, { base64: "3" }, { base64: "4" }],
        }],
      }),
    ValidationError,
  );
});

Deno.test("validateTryonParams rejects a source with both path and base64", () => {
  assertThrows(
    () =>
      validateTryonParams({ ...validParams, avatar: { path: "p", base64: "b" } }),
    ValidationError,
  );
});

Deno.test("validateTryonParams strips a garment detail a caller tried to set", () => {
  // Only resolveProductGarment may attach one, and it runs after this guard.
  const job = validateTryonParams({
    ...validParams,
    garments: [
      { images: [{ base64: "B" }], detail: "smuggled" } as TryonParams[
        "garments"
      ][number],
    ],
  });
  assertEquals(job.garments, [{ images: [{ base64: "B" }] }]);
});

Deno.test("validateTryonParams accepts a product-ref garment", () => {
  validateTryonParams({
    ...validParams,
    garments: [{ productId: "33333333-3333-3333-3333-333333333333" }],
  }); // does not throw
});

Deno.test("validateTryonParams rejects an empty productId", () => {
  assertThrows(
    () => validateTryonParams({ ...validParams, garments: [{ productId: "" }] }),
    ValidationError,
  );
});

Deno.test("validateTryonParams rejects a non-string productId with a productId error", () => {
  assertThrows(
    () =>
      validateTryonParams({
        ...validParams,
        garments: [{ productId: 123 as unknown as string }],
      }),
    ValidationError,
    "productId",
  );
});

Deno.test("validateTryonParams rejects an invalid mode", () => {
  assertThrows(
    () =>
      validateTryonParams({
        ...validParams,
        mode: "gif" as unknown as TryonParams["mode"],
      }),
    ValidationError,
    "mode",
  );
});

Deno.test("validateTryonParams rejects an overlong scenePrompt", () => {
  assertThrows(
    () =>
      validateTryonParams({
        ...validParams,
        scenePrompt: "x".repeat(LIMITS.MAX_PROMPT_LENGTH + 1),
      }),
    ValidationError,
    "scenePrompt",
  );
});

Deno.test("validateTryonParams rejects an overlong transitionPrompt", () => {
  assertThrows(
    () =>
      validateTryonParams({
        ...validParams,
        mode: "video",
        transitionPrompt: "x".repeat(LIMITS.MAX_PROMPT_LENGTH + 1),
      }),
    ValidationError,
    "transitionPrompt",
  );
});

Deno.test("validateTryonParams returns params with sources narrowed", () => {
  const job = validateTryonParams({
    ...validParams,
    avatar: { base64: "AAAA", path: "" } as unknown as TryonParams["avatar"],
    garments: [{
      images: [{ base64: "BBBB", path: "" } as unknown as TryonParams["avatar"]],
    }],
    scenePrompt: "beach",
  });
  assertEquals(job.avatar, { base64: "AAAA" });
  assertEquals(job.garments, [{ images: [{ base64: "BBBB" }] }]);
  assertEquals(job.userId, "u1");
  assertEquals(job.mode, "image");
  assertEquals(job.scenePrompt, "beach");
});

Deno.test("validateTryonParams returns a product-ref garment as just its id", () => {
  const job = validateTryonParams({
    ...validParams,
    garments: [
      {
        productId: "33333333-3333-3333-3333-333333333333",
        images: [{ base64: "IGNORED" }],
      } as unknown as TryonParams["garments"][number],
    ],
  });
  assertEquals(job.garments, [
    { productId: "33333333-3333-3333-3333-333333333333" },
  ]);
});

Deno.test("requireImageSource keeps exactly the one usable key", () => {
  assertEquals(requireImageSource({ path: "a.jpg" }, "avatar"), { path: "a.jpg" });
  assertEquals(requireImageSource({ base64: "AAA", path: "" }, "avatar"), {
    base64: "AAA",
  });
});

Deno.test("requireImageSource rejects zero or two usable keys", () => {
  assertThrows(() => requireImageSource({}, "avatar"), ValidationError);
  assertThrows(
    () => requireImageSource({ path: "a", base64: "b" }, "avatar"),
    ValidationError,
  );
});

Deno.test("normalizeText trims, blanks to undefined, and never truncates", () => {
  assertEquals(normalizeText("  hi  "), "hi");
  assertEquals(normalizeText("   "), undefined);
  assertEquals(normalizeText(42), undefined);
  const long = "x".repeat(LIMITS.MAX_PROMPT_LENGTH + 10);
  assertEquals(normalizeText(long)?.length, LIMITS.MAX_PROMPT_LENGTH + 10);
});

Deno.test("requireString rejects missing and empty values", () => {
  assertEquals(requireString("ok", "field"), "ok");
  assertThrows(() => requireString("", "field"), ValidationError, "field");
  assertThrows(() => requireString(undefined, "field"), ValidationError);
});
