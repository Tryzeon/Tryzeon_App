import { assertEquals, assertThrows } from "jsr:@std/assert";
import { assertTryonParams, parseTryonParams } from "./validate.ts";
import { LIMITS, ValidationError, type TryonParams } from "./types.ts";

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

Deno.test("parseTryonParams keeps a trimmed garment detail", () => {
  const params = parseTryonParams(
    {
      avatar: { base64: "A" },
      garments: [{ images: [{ base64: "B" }], detail: "  Material: Cotton  " }],
    },
    "u1",
  );
  assertEquals(params.garments[0].detail, "Material: Cotton");
});

Deno.test("parseTryonParams drops a blank garment detail", () => {
  const params = parseTryonParams(
    {
      avatar: { base64: "A" },
      garments: [{ images: [{ base64: "B" }], detail: "   " }],
    },
    "u1",
  );
  assertEquals(params.garments[0].detail, undefined);
});

Deno.test("parseTryonParams caps garment detail length", () => {
  const long = "x".repeat(LIMITS.MAX_GARMENT_DETAIL_LENGTH + 50);
  const params = parseTryonParams(
    {
      avatar: { base64: "A" },
      garments: [{ images: [{ base64: "B" }], detail: long }],
    },
    "u1",
  );
  assertEquals(params.garments[0].detail?.length, LIMITS.MAX_GARMENT_DETAIL_LENGTH);
});

Deno.test("assertTryonParams rejects a non-string garment detail", () => {
  assertThrows(
    () =>
      assertTryonParams({
        ...validParams,
        garments: [
          { images: [{ base64: "B" }], detail: 42 as unknown as string },
        ],
      }),
    ValidationError,
  );
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
