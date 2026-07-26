import { assertEquals, assertThrows } from "jsr:@std/assert";
import { parseTryonParams } from "./request.ts";
import { LIMITS, ValidationError } from "../_shared/tryon/index.ts";
import type { GarmentMaterial } from "../_shared/tryon/index.ts";

/** The parser takes raw text; encode fixtures so tests hit the real entry point. */
function parse(body: unknown, userId: string) {
  return parseTryonParams(JSON.stringify(body), userId);
}

Deno.test("parseTryonParams rejects unparseable JSON as a validation error", () => {
  // Not a special case for the entry point to translate: a malformed body is a
  // malformed request, so it raises the same error class as a malformed field
  // and lands on 400 rather than escaping as a SyntaxError.
  assertThrows(
    () => parseTryonParams("{not json", "u1"),
    ValidationError,
    "valid JSON",
  );
});

Deno.test("parseTryonParams rejects an empty body", () => {
  assertThrows(() => parseTryonParams("", "u1"), ValidationError, "valid JSON");
});

Deno.test("parseTryonParams shapes wire body, keeps mode, attaches userId", () => {
  const params = parse(
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
  const params = parse(
    {
      avatar: { base64: "A" },
      garments: [{ images: [{ base64: "B" }], detail: "  Material: Cotton  " }],
    },
    "u1",
  );
  assertEquals(params.garments, [{
    images: [{ base64: "B" }],
    detail: "Material: Cotton",
  }]);
});

Deno.test("parseTryonParams drops a blank garment detail", () => {
  const params = parse(
    {
      avatar: { base64: "A" },
      garments: [{ images: [{ base64: "B" }], detail: "   " }],
    },
    "u1",
  );
  assertEquals(params.garments, [{ images: [{ base64: "B" }] }]);
});

Deno.test("parseTryonParams preserves an overlong garment detail for the core to reject", () => {
  // Parsing never truncates user input: the value survives intact so
  // validateTryonParams can reject it with a 400 instead of the caller being told
  // "accepted" while its text was silently cut short.
  const long = "x".repeat(LIMITS.MAX_GARMENT_DETAIL_LENGTH + 50);
  const params = parse(
    {
      avatar: { base64: "A" },
      garments: [{ images: [{ base64: "B" }], detail: long }],
    },
    "u1",
  );
  assertEquals(
    (params.garments[0] as GarmentMaterial).detail?.length,
    LIMITS.MAX_GARMENT_DETAIL_LENGTH + 50,
  );
});

Deno.test("parseTryonParams defaults an omitted mode to image", () => {
  const params = parse(
    { avatar: { base64: "A" }, garments: [{ images: [{ base64: "B" }] }] },
    "u1",
  );
  assertEquals(params.mode, "image");
});

Deno.test("parseTryonParams passes an unknown mode through for the core to reject", () => {
  // Not coerced to "image": that would run — and charge — a job the caller did
  // not ask for, and would leave the core's mode check unreachable from here.
  // The rejection itself is validateTryonParams' test.
  const params = parse(
    {
      avatar: { base64: "A" },
      garments: [{ images: [{ base64: "B" }] }],
      mode: "Video",
    },
    "u1",
  );
  assertEquals(params.mode, "Video");
});

Deno.test("parseTryonParams rejects non-object body", () => {
  assertThrows(() => parse(null, "u1"), ValidationError);
});

Deno.test("parseTryonParams rejects a non-array garments field", () => {
  assertThrows(
    () => parse({ avatar: { base64: "A" }, garments: "nope" }, "u1"),
    ValidationError,
  );
});

Deno.test("parseTryonParams accepts a product-ref garment", () => {
  const params = parse(
    {
      avatar: { base64: "A" },
      garments: [{ productId: "11111111-1111-1111-1111-111111111111" }],
    },
    "u1",
  );
  assertEquals(params.garments, [
    { productId: "11111111-1111-1111-1111-111111111111" },
  ]);
});

Deno.test("parseTryonParams accepts a mixed product + material garment list", () => {
  const params = parse(
    {
      avatar: { base64: "A" },
      garments: [
        { productId: "22222222-2222-2222-2222-222222222222" },
        { images: [{ base64: "B" }] },
      ],
    },
    "u1",
  );
  assertEquals(params.garments.length, 2);
  assertEquals(params.garments[0], {
    productId: "22222222-2222-2222-2222-222222222222",
  });
  assertEquals(params.garments[1], { images: [{ base64: "B" }] });
});

Deno.test("parseTryonParams decodes structure and defers invariants to the core", () => {
  // parse does not enforce invariants; an empty productId decodes cleanly and
  // is rejected later by validateTryonParams inside runTryonJob.
  const params = parse(
    { avatar: { base64: "A" }, garments: [{ productId: "" }] },
    "u1",
  );
  assertEquals(params.garments, [{ productId: "" }]);
});

Deno.test("parseTryonParams trims prompts without capping them", () => {
  const long = "x".repeat(LIMITS.MAX_PROMPT_LENGTH + 50);
  const params = parse(
    {
      avatar: { base64: "A" },
      garments: [{ images: [{ base64: "B" }] }],
      mode: "video",
      scenePrompt: "  studio backdrop  ",
      transitionPrompt: long,
    },
    "u1",
  );
  assertEquals(params.scenePrompt, "studio backdrop");
  assertEquals(params.transitionPrompt?.length, LIMITS.MAX_PROMPT_LENGTH + 50);
});

Deno.test("parseTryonParams drops a blank scenePrompt", () => {
  const params = parse(
    {
      avatar: { base64: "A" },
      garments: [{ images: [{ base64: "B" }] }],
      scenePrompt: "   ",
    },
    "u1",
  );
  assertEquals(params.scenePrompt, undefined);
});
