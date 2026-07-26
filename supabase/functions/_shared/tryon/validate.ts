/**
 * The core's domain guard, plus the small normalization primitives every
 * adapter's request parser shares.
 *
 * The primitives split by whether a missing value is legal, and the names say
 * which: `require*` decodes a mandatory field and throws when it cannot,
 * `normalize*` decodes an optional one and never throws. The `label` parameter
 * follows the same line — it exists only to name the field in an error, so its
 * presence marks exactly the functions that can raise one.
 *
 * Policy: normalization never silently changes the meaning of user input — it
 * only trims and narrows shapes. Every limit is enforced by `validateTryonParams`,
 * which throws. Truncation is reserved for server-generated text (see
 * `buildProductGarmentDetail`), so a caller is never told "accepted" while its
 * input was quietly cut short.
 */
import { nonEmptyStr } from "../text.ts";
import { ValidationError } from "./errors.ts";
import { isGarmentRef, LIMITS } from "./types.ts";
import type { GarmentInput, ImageSource, TryonParams } from "./types.ts";

/**
 * Decode an unknown value into an ImageSource carrying exactly one usable key.
 * Raises when it has neither or both — an image addressed two ways is a caller
 * bug, not something to silently pick a winner for.
 */
export function requireImageSource(source: unknown, label: string): ImageSource {
  if (typeof source !== "object" || source === null) {
    throw new ValidationError(`${label} must be an object`);
  }
  const s = source as Record<string, unknown>;
  const keys = (["path", "base64"] as const).filter(
    (k) => typeof s[k] === "string" && (s[k] as string).length > 0,
  );
  if (keys.length !== 1) {
    throw new ValidationError(`${label} must have exactly one of path | base64`);
  }
  return { [keys[0]]: s[keys[0]] } as ImageSource;
}

/** Require a non-empty string, for adapter parsers decoding wire fields. */
export function requireString(value: unknown, label: string): string {
  if (typeof value !== "string" || value.length === 0) {
    throw new ValidationError(`${label} is required`);
  }
  return value;
}

/**
 * Trim an optional text field; blank or non-string becomes undefined. The
 * shared `nonEmptyStr` spelled for this module's optional convention, since
 * `TryonParams`' optional fields are `undefined`-typed, not nullable.
 */
export function normalizeText(value: unknown): string | undefined {
  return nonEmptyStr(value) ?? undefined;
}

/** Guard an optional text field: if present it must be a string within `max`. */
function assertOptionalText(value: unknown, label: string, max: number): void {
  if (value === undefined) return;
  if (typeof value !== "string") {
    throw new ValidationError(`${label} must be a string`);
  }
  if (value.length > max) {
    throw new ValidationError(`${label} too long (max ${max})`);
  }
}

/** Validate one garment and return it with its image sources narrowed. */
function validateGarment(garment: GarmentInput): GarmentInput {
  if (typeof garment !== "object" || garment === null) {
    throw new ValidationError("each garment must be an object");
  }
  if (isGarmentRef(garment)) {
    return { productId: requireString(garment.productId, "garment productId") };
  }
  if (!Array.isArray(garment.images) || garment.images.length === 0) {
    throw new ValidationError("each garment must have a non-empty images array");
  }
  if (garment.images.length > LIMITS.MAX_IMAGES_PER_GARMENT) {
    throw new ValidationError(
      `too many images for a garment (max ${LIMITS.MAX_IMAGES_PER_GARMENT})`,
    );
  }
  // No `detail` to check: a caller cannot supply one. The only description a
  // job carries is the product text `resolveProductGarment` attaches after this
  // guard has run, which is capped where it is built.
  return {
    images: garment.images.map((img) => requireImageSource(img, "garment image")),
  };
}

/**
 * Guard the lib's domain invariants and return the params with every image
 * source narrowed to exactly one usable key. Called by runTryonJob so every
 * caller (app, LIFF, LINE) is checked uniformly.
 *
 * It returns rather than merely asserting because normalization already
 * produces the value the job should run on: handing it back means the
 * orchestrator consumes checked data instead of re-reading the raw input.
 */
export function validateTryonParams(params: TryonParams): TryonParams {
  requireString(params.userId, "userId");

  const avatar = requireImageSource(params.avatar, "avatar");

  if (!Array.isArray(params.garments) || params.garments.length === 0) {
    throw new ValidationError("garments must be a non-empty array");
  }
  if (params.garments.length > LIMITS.MAX_GARMENTS) {
    throw new ValidationError(`too many garments (max ${LIMITS.MAX_GARMENTS})`);
  }
  const garments = params.garments.map(validateGarment);

  if (params.mode !== "image" && params.mode !== "video") {
    throw new ValidationError("mode must be 'image' or 'video'");
  }

  assertOptionalText(
    params.scenePrompt, 
    "scenePrompt", 
    LIMITS.MAX_PROMPT_LENGTH
  );
  assertOptionalText(
    params.transitionPrompt,
    "transitionPrompt",
    LIMITS.MAX_PROMPT_LENGTH,
  );

  return { ...params, avatar, garments };
}
