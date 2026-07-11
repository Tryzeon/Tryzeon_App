import { assertEquals, assertThrows } from "jsr:@std/assert";
import { assertTryonParams, parseTryonParams } from "./validate.ts";
import { ValidationError, type TryonParams } from "./types.ts";

const validParams: TryonParams = {
  userId: "u1",
  avatar: { base64: "AAAA" },
  garments: [{ images: [{ base64: "BBBB" }] }],
  mode: "image",
};

Deno.test("assertTryonParams accepts valid params", () => {
  assertTryonParams(validParams); // does not throw
});

Deno.test("assertTryonParams rejects empty garments", () => {
  assertThrows(
    () => assertTryonParams({ ...validParams, garments: [] }),
    ValidationError,
  );
});

Deno.test("assertTryonParams rejects too many garments", () => {
  const g = { images: [{ base64: "X" }] };
  assertThrows(
    () => assertTryonParams({ ...validParams, garments: [g, g, g, g] }),
    ValidationError,
  );
});

Deno.test("assertTryonParams rejects too many images in a garment", () => {
  assertThrows(
    () =>
      assertTryonParams({
        ...validParams,
        garments: [{
          images: [{ base64: "1" }, { base64: "2" }, { base64: "3" }, { base64: "4" }],
        }],
      }),
    ValidationError,
  );
});

Deno.test("assertTryonParams rejects a source with both path and base64", () => {
  assertThrows(
    () =>
      assertTryonParams({ ...validParams, avatar: { path: "p", base64: "b" } }),
    ValidationError,
  );
});

Deno.test("parseTryonParams shapes wire body, coerces mode, attaches userId", () => {
  const params = parseTryonParams(
    {
      avatar: { path: "u1/a.jpg" },
      garments: [{ images: [{ path: "u1/top/x.jpg" }] }],
      mode: "video",
      transitionPrompt: "spin",
    },
    "u1",
  );
  assertEquals(params.userId, "u1");
  assertEquals(params.mode, "video");
  assertEquals(params.avatar, { path: "u1/a.jpg" });
  assertEquals(params.garments, [{ images: [{ path: "u1/top/x.jpg" }] }]);
  assertEquals(params.transitionPrompt, "spin");
});

Deno.test("parseTryonParams defaults unknown mode to image", () => {
  const params = parseTryonParams(
    { avatar: { base64: "A" }, garments: [{ images: [{ base64: "B" }] }] },
    "u1",
  );
  assertEquals(params.mode, "image");
});

Deno.test("parseTryonParams rejects non-object body", () => {
  assertThrows(() => parseTryonParams(null, "u1"), ValidationError);
});
