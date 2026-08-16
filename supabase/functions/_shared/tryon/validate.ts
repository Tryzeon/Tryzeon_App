/**
 * The core's domain guard, plus the one decoding primitive that is specific to
 * try-on's wire fields. The generic ones (`requireString`, `normalizeText`) and
 * the error they raise are shared with every other core and live in
 * `_shared/validation.ts`.
 *
 * Policy: normalization never silently changes the meaning of user input — it
 * only trims and narrows shapes. Every limit is enforced by `validateTryonParams`,
 * which throws. Truncation is reserved for server-generated text (see
 * `buildProductGarmentDetail`), so a caller is never told "accepted" while its
 * input was quietly cut short.
 */
import { requireString, ValidationError } from "../validation.ts";
import { isProductRef, isWardrobeRef, LIMITS } from "./types.ts";
import type {
  AvatarOverride,
  GarmentInput,
  ImageSource,
  TryonParams,
} from "./types.ts";

/**
 * Decode an unknown value into an ImageSource carrying exactly one usable key.
 * Raises when it has neither or both — an image addressed two ways is a caller
 * bug, not something to silently pick a winner for.
 */
export function requireImageSource(
  source: unknown,
  label: string,
): ImageSource {
  if (typeof source !== "object" || source === null) {
    throw new ValidationError(`${label} must be an object`);
  }
  const s = source as Record<string, unknown>;
  const keys = (["path", "base64"] as const).filter(
    (k) => typeof s[k] === "string" && (s[k] as string).length > 0,
  );
  if (keys.length !== 1) {
    throw new ValidationError(
      `${label} must have exactly one of path | base64`,
    );
  }
  return { [keys[0]]: s[keys[0]] } as ImageSource;
}

/**
 * Decode the optional avatar override. Only inline bytes can override; the
 * legacy `{ path }` shape shipped clients still send means "no override", and
 * so does `null` (some encoders serialize an absent field that way). Anything
 * else that is not a usable `{ base64 }` is rejected rather than silently
 * falling back — that silent fallback is the stale-photo bug this replaces.
 */
function optionalAvatarOverride(source: unknown): AvatarOverride | undefined {
  if (source === undefined || source === null) return undefined;
  if (typeof source !== "object") {
    throw new ValidationError("avatar must be an object");
  }
  const s = source as Record<string, unknown>;
  const base64 = s.base64;
  if (base64 === undefined) {
    const hasPath = typeof s.path === "string" && s.path.length > 0;
    if (hasPath) return undefined;
    throw new ValidationError("avatar must have a usable base64");
  }
  if (typeof base64 !== "string" || base64.length === 0) {
    throw new ValidationError("avatar base64 must be a non-empty string");
  }
  return { base64 };
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
  if (isProductRef(garment)) {
    return { productId: requireString(garment.productId, "garment productId") };
  }
  if (isWardrobeRef(garment)) {
    return {
      wardrobeItemId: requireString(
        garment.wardrobeItemId,
        "garment wardrobeItemId",
      ),
    };
  }
  if (!Array.isArray(garment.images) || garment.images.length === 0) {
    throw new ValidationError(
      "each garment must have a non-empty images array",
    );
  }
  if (garment.images.length > LIMITS.MAX_IMAGES_PER_GARMENT) {
    throw new ValidationError(
      `too many images for a garment (max ${LIMITS.MAX_IMAGES_PER_GARMENT})`,
    );
  }
  // No `detail` to check: a caller cannot supply one. The only description a
  // job carries is the text a resolver attaches after this guard has run,
  // which is capped where it is built.
  return {
    images: garment.images.map((img) =>
      requireImageSource(img, "garment image")
    ),
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

  const avatar = optionalAvatarOverride(params.avatar);

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
    LIMITS.MAX_PROMPT_LENGTH,
  );
  assertOptionalText(
    params.transitionPrompt,
    "transitionPrompt",
    LIMITS.MAX_PROMPT_LENGTH,
  );

  return { ...params, avatar, garments };
}
