import { assertEquals, assertThrows } from "jsr:@std/assert@^1.0.19";
import { validateTryonParams } from "./validate.ts";
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
          images: [{ base64: "1" }, { base64: "2" }, { base64: "3" }, {
            base64: "4",
          }],
        }],
      }),
    ValidationError,
  );
});

Deno.test("validateTryonParams rejects a garment image named by path", () => {
  assertThrows(
    () =>
      validateTryonParams({
        ...validParams,
        garments: [{
          images: [{ path: "p" } as unknown as { base64: string }],
        }],
      }),
    ValidationError,
    "garment image",
  );
});

Deno.test("validateTryonParams rejects a path even alongside usable bytes", () => {
  assertThrows(
    () =>
      validateTryonParams({
        ...validParams,
        garments: [{
          images: [{ path: "p", base64: "" } as unknown as { base64: string }],
        }],
      }),
    ValidationError,
  );
});

Deno.test("validateTryonParams keeps an inline avatar override", () => {
  const job = validateTryonParams({
    ...validParams,
    avatar: { base64: "AAAA" },
  });
  assertEquals(job.avatar, { base64: "AAAA" });
});

Deno.test("validateTryonParams treats an omitted avatar as no override", () => {
  const job = validateTryonParams({ ...validParams, avatar: undefined });
  assertEquals(job.avatar, undefined);
});

Deno.test("validateTryonParams treats a legacy path avatar as no override", () => {
  // Shipped app builds still send the profile path; the job falls back to the
  // stored photo, which is the same picture, only current.
  const job = validateTryonParams({
    ...validParams,
    avatar: { path: "u1/a.jpg" } as unknown as TryonParams["avatar"],
  });
  assertEquals(job.avatar, undefined);
});

Deno.test("validateTryonParams rejects an unusable avatar base64", () => {
  assertThrows(
    () => validateTryonParams({ ...validParams, avatar: { base64: "" } }),
    ValidationError,
    "avatar",
  );
  assertThrows(
    () =>
      validateTryonParams({
        ...validParams,
        avatar: { base64: 5 as unknown as string },
      }),
    ValidationError,
    "avatar",
  );
});

Deno.test("validateTryonParams treats a null avatar as no override", () => {
  // Some JSON encoders serialize an absent field as null rather than omitting it.
  const job = validateTryonParams({
    ...validParams,
    avatar: null as unknown as TryonParams["avatar"],
  });
  assertEquals(job.avatar, undefined);
});

Deno.test("validateTryonParams rejects a non-object avatar", () => {
  assertThrows(
    () =>
      validateTryonParams({
        ...validParams,
        avatar: "AAAA" as unknown as TryonParams["avatar"],
      }),
    ValidationError,
    "avatar",
  );
});

Deno.test("validateTryonParams rejects an empty-object avatar", () => {
  assertThrows(
    () =>
      validateTryonParams({
        ...validParams,
        avatar: {} as unknown as TryonParams["avatar"],
      }),
    ValidationError,
    "avatar",
  );
});

Deno.test("validateTryonParams strips a garment detail a caller tried to set", () => {
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
    () =>
      validateTryonParams({ ...validParams, garments: [{ productId: "" }] }),
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
    avatar: { base64: "AAAA" },
    garments: [{ images: [{ base64: "BBBB" }] }],
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

Deno.test("validateTryonParams accepts a wardrobe ref", () => {
  const job = validateTryonParams({
    ...validParams,
    garments: [{ wardrobeItemId: "44444444-4444-4444-4444-444444444444" }],
  });
  assertEquals(job.garments, [
    { wardrobeItemId: "44444444-4444-4444-4444-444444444444" },
  ]);
});

Deno.test("validateTryonParams rejects an empty wardrobeItemId", () => {
  assertThrows(
    () =>
      validateTryonParams({
        ...validParams,
        garments: [{ wardrobeItemId: "" }],
      }),
    ValidationError,
    "wardrobeItemId",
  );
});

Deno.test("validateTryonParams keeps a garment's sizeId", () => {
  const params = validateTryonParams({
    userId: "u1",
    garments: [{ productId: "p1", sizeId: "s1" }],
    mode: "image",
  });

  assertEquals(params.garments[0], { productId: "p1", sizeId: "s1" });
});

Deno.test("validateTryonParams omits sizeId when the caller sent none", () => {
  const params = validateTryonParams({
    userId: "u1",
    garments: [{ productId: "p1" }],
    mode: "image",
  });

  assertEquals(params.garments[0], { productId: "p1" });
});

Deno.test("validateTryonParams rejects a non-string sizeId", () => {
  assertThrows(
    () =>
      validateTryonParams({
        userId: "u1",
        garments: [
          {
            productId: "p1",
            sizeId: 7,
          } as unknown as TryonParams["garments"][number],
        ],
        mode: "image",
      }),
    ValidationError,
    "garment sizeId",
  );
});

const animateParams: TryonParams = {
  userId: "u1",
  garments: [],
  mode: "video",
  baseImage: { base64: "FINISHED" },
};

Deno.test("validateTryonParams accepts an animate job with no garments", () => {
  const out = validateTryonParams(animateParams);
  assertEquals(out.baseImage, { base64: "FINISHED" });
  assertEquals(out.garments, []);
  assertEquals(out.avatar, undefined);
});

Deno.test("validateTryonParams rejects baseImage in image mode", () => {
  assertThrows(
    () => validateTryonParams({ ...animateParams, mode: "image" }),
    ValidationError,
    "baseImage requires mode 'video'",
  );
});

Deno.test("validateTryonParams rejects baseImage combined with garments", () => {
  assertThrows(
    () =>
      validateTryonParams({
        ...animateParams,
        garments: [{ images: [{ base64: "G" }] }],
      }),
    ValidationError,
    "garments",
  );
});

Deno.test("validateTryonParams rejects baseImage combined with an avatar", () => {
  assertThrows(
    () =>
      validateTryonParams({ ...animateParams, avatar: { base64: "A" } }),
    ValidationError,
    "avatar",
  );
});

Deno.test("validateTryonParams accepts a scenePrompt with baseImage and drops it", () => {
  const out = validateTryonParams({ ...animateParams, scenePrompt: "studio" });
  assertEquals(out.scenePrompt, undefined);
  assertEquals(out.baseImage, { base64: "FINISHED" });
});

Deno.test("validateTryonParams keeps the transitionPrompt with baseImage", () => {
  const out = validateTryonParams({ ...animateParams, transitionPrompt: "spin" });
  assertEquals(out.transitionPrompt, "spin");
});

Deno.test("validateTryonParams rejects an empty baseImage base64", () => {
  assertThrows(
    () => validateTryonParams({ ...animateParams, baseImage: { base64: "" } }),
    ValidationError,
    "baseImage",
  );
});

Deno.test("validateTryonParams rejects an oversized baseImage", () => {
  assertThrows(
    () =>
      validateTryonParams({
        ...animateParams,
        baseImage: { base64: "x".repeat(LIMITS.MAX_BASE64_LENGTH + 1) },
      }),
    ValidationError,
    "too large",
  );
});

Deno.test("validateTryonParams accepts a baseImage exactly at the limit", () => {
  const out = validateTryonParams({
    ...animateParams,
    baseImage: { base64: "x".repeat(LIMITS.MAX_BASE64_LENGTH) },
  });
  assertEquals(out.baseImage?.base64.length, LIMITS.MAX_BASE64_LENGTH);
});

Deno.test("validateTryonParams rejects a non-object baseImage", () => {
  assertThrows(
    () =>
      validateTryonParams({
        ...animateParams,
        baseImage: "nope" as unknown as TryonParams["baseImage"],
      }),
    ValidationError,
    "baseImage",
  );
});

Deno.test("validateTryonParams still requires garments without a baseImage", () => {
  assertThrows(
    () => validateTryonParams({ ...animateParams, baseImage: undefined }),
    ValidationError,
    "garments",
  );
});

Deno.test("validateTryonParams rejects an overlong stylingPrompt", () => {
  assertThrows(
    () =>
      validateTryonParams({
        ...validParams,
        stylingPrompt: "x".repeat(LIMITS.MAX_PROMPT_LENGTH + 1),
      }),
    ValidationError,
    "stylingPrompt",
  );
});

Deno.test("validateTryonParams keeps the stylingPrompt on a generate job", () => {
  const job = validateTryonParams({
    ...validParams,
    stylingPrompt: "tucked into the waistband",
  });
  assertEquals(job.stylingPrompt, "tucked into the waistband");
});

Deno.test("validateTryonParams accepts a stylingPrompt with baseImage and drops it", () => {
  const out = validateTryonParams({
    ...animateParams,
    stylingPrompt: "tucked in",
  });
  assertEquals(out.stylingPrompt, undefined);
  assertEquals(out.baseImage, { base64: "FINISHED" });
});

Deno.test("validateTryonParams defaults a missing engine to standard", () => {
  assertEquals(validateTryonParams(validParams).engine, "standard");
});

Deno.test("validateTryonParams keeps the advanced engine on a generate job", () => {
  const job = validateTryonParams({ ...validParams, engine: "advanced" });
  assertEquals(job.engine, "advanced");
});

Deno.test("validateTryonParams rejects an unknown engine", () => {
  assertThrows(
    () =>
      validateTryonParams({
        ...validParams,
        engine: "turbo" as TryonParams["engine"],
      }),
    ValidationError,
    "engine",
  );
});

Deno.test("validateTryonParams keeps the engine on an animate job", () => {
  const out = validateTryonParams({ ...animateParams, engine: "advanced" });
  assertEquals(out.engine, "advanced");
  assertEquals(out.baseImage, { base64: "FINISHED" });
});

Deno.test("validateTryonParams defaults an animate job's engine to standard", () => {
  assertEquals(validateTryonParams(animateParams).engine, "standard");
});
