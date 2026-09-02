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
  BaseImage,
  GarmentInput,
  GarmentMaterial,
  ProductRef,
  TryonParams,
} from "./types.ts";

/**
 * Decode an unknown value into the inline bytes a caller is allowed to send.
 * A `{ path }` is rejected rather than ignored: silently dropping it would run
 * the job against whatever else the garment carried, which is not what the
 * caller asked for. See {@link GarmentMaterial} for why paths are not in the
 * contract at all.
 */
function requireInlineImage(
  source: unknown,
  label: string,
): { base64: string } {
  if (typeof source !== "object" || source === null) {
    throw new ValidationError(`${label} must be an object`);
  }
  const base64 = (source as Record<string, unknown>).base64;
  if (typeof base64 !== "string" || base64.length === 0) {
    throw new ValidationError(`${label} must have a non-empty base64`);
  }
  return { base64 };
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

function optionalBaseImage(source: unknown): BaseImage | undefined {
  if (source === undefined || source === null) return undefined;
  if (typeof source !== "object") {
    throw new ValidationError("baseImage must be an object");
  }
  const base64 = (source as Record<string, unknown>).base64;
  if (typeof base64 !== "string" || base64.length === 0) {
    throw new ValidationError("baseImage must have a non-empty base64");
  }
  // The entry point reads the whole body into memory before this guard runs, so
  // without a ceiling an authenticated caller could spend a function's memory —
  // and a quota charge — on something Veo was going to reject anyway.
  if (base64.length > LIMITS.MAX_BASE64_LENGTH) {
    throw new ValidationError(
      `baseImage too large (max ${LIMITS.MAX_BASE64_LENGTH} base64 chars)`,
    );
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
    const ref: ProductRef = {
      productId: requireString(garment.productId, "garment productId"),
    };
    if (garment.sizeId !== undefined) {
      ref.sizeId = requireString(garment.sizeId, "garment sizeId");
    }
    return ref;
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
      requireInlineImage(img, "garment image")
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

  if (params.mode !== "image" && params.mode !== "video") {
    throw new ValidationError("mode must be 'image' or 'video'");
  }

  // Rejected rather than defaulted: an unrecognised engine means the caller
  // asked for a model this deployment does not have, and quietly running the
  // standard one would bill them for something they did not ask for.
  const engine = params.engine ?? "standard";
  if (engine !== "standard" && engine !== "advanced") {
    throw new ValidationError("engine must be 'standard' or 'advanced'");
  }

  assertOptionalText(
    params.scenePrompt,
    "scenePrompt",
    LIMITS.MAX_PROMPT_LENGTH,
  );
  assertOptionalText(
    params.stylingPrompt,
    "stylingPrompt",
    LIMITS.MAX_PROMPT_LENGTH,
  );
  assertOptionalText(
    params.transitionPrompt,
    "transitionPrompt",
    LIMITS.MAX_PROMPT_LENGTH,
  );

  const baseImage = optionalBaseImage(params.baseImage);
  if (baseImage) {
    // A garment, an avatar or a non-video mode alongside a finished picture is
    // a contradiction the server must not resolve by guessing — an animate job
    // always spends video quota, so the body it charges for has to be the body
    // the caller meant.
    if (params.mode !== "video") {
      throw new ValidationError("baseImage requires mode 'video'");
    }
    if (Array.isArray(params.garments) && params.garments.length > 0) {
      throw new ValidationError("baseImage cannot be combined with garments");
    }
    if (params.avatar !== undefined && params.avatar !== null) {
      throw new ValidationError("baseImage cannot be combined with an avatar");
    }
    // The scene and styling prompts are not contradictions, just inapplicable:
    // they are ambient user config rather than something the caller attached to
    // this request, so a client that sends them uniformly is tolerated. Dropped
    // here so the job runs on params that say what will actually happen.
    //
    // The engine survives, unlike them. Today nothing on this path reads it —
    // animating runs no image pass — but it names a model tier rather than a
    // prompt, and a video model that grows tiers would need it back. Keeping it
    // costs a field; dropping it would make that a change to the guard.
    return {
      ...params,
      avatar: undefined,
      garments: [],
      engine,
      scenePrompt: undefined,
      stylingPrompt: undefined,
      baseImage,
    };
  }

  const avatar = optionalAvatarOverride(params.avatar);

  if (!Array.isArray(params.garments) || params.garments.length === 0) {
    throw new ValidationError("garments must be a non-empty array");
  }
  if (params.garments.length > LIMITS.MAX_GARMENTS) {
    throw new ValidationError(`too many garments (max ${LIMITS.MAX_GARMENTS})`);
  }
  const garments = params.garments.map(validateGarment);

  return { ...params, avatar, engine, garments, baseImage: undefined };
}
