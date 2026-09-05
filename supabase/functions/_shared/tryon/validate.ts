/**
 * Policy: normalization never silently changes the meaning of user input — it
 * only trims and narrows shapes. Every limit is enforced by
 * `validateTryonParams`, which throws. Truncation is reserved for
 * server-generated text (see `buildProductGarmentDetail`), so a caller is never
 * told "accepted" while its input was quietly cut short.
 */
import { requireString, ValidationError } from "../validation.ts";
import { isProductRef, isWardrobeRef, LIMITS } from "./types.ts";
import type {
  AvatarOverride,
  BaseImage,
  GarmentInput,
  ProductRef,
  TryonParams,
} from "./types.ts";

/**
 * The entry point reads the whole body into memory before any guard here runs,
 * so without a ceiling an authenticated caller could spend a function's memory
 * — and a quota charge — on something the model was going to reject anyway.
 */
function requireBase64(value: unknown, label: string): string {
  if (typeof value !== "string" || value.length === 0) {
    throw new ValidationError(`${label} must have a non-empty base64`);
  }
  if (value.length > LIMITS.MAX_BASE64_LENGTH) {
    throw new ValidationError(
      `${label} too large (max ${LIMITS.MAX_BASE64_LENGTH} base64 chars)`,
    );
  }
  return value;
}

/**
 * A `{ path }` is rejected rather than ignored: silently dropping it would run
 * the job against whatever else the garment carried, which is not what the
 * caller asked for. Checked before the bytes so a client still sending the
 * retired shape is told what is actually wrong with it.
 */
function requireInlineImage(
  source: unknown,
  label: string,
): { base64: string } {
  if (typeof source !== "object" || source === null) {
    throw new ValidationError(`${label} must be an object`);
  }
  const s = source as Record<string, unknown>;
  if (typeof s.path === "string" && s.path.length > 0) {
    throw new ValidationError(`${label} must be inline bytes, not a path`);
  }
  return { base64: requireBase64(s.base64, label) };
}

/**
 * The legacy `{ path }` shape shipped clients still send means "no override",
 * and so does `null`. Anything else that is not a usable `{ base64 }` is
 * rejected rather than silently falling back — that silent fallback is the
 * stale-photo bug this replaces.
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
  return { base64: requireBase64(base64, "avatar") };
}

function optionalBaseImage(source: unknown): BaseImage | undefined {
  if (source === undefined || source === null) return undefined;
  if (typeof source !== "object") {
    throw new ValidationError("baseImage must be an object");
  }
  const base64 = (source as Record<string, unknown>).base64;
  return { base64: requireBase64(base64, "baseImage") };
}

function assertOptionalText(value: unknown, label: string, max: number): void {
  if (value === undefined) return;
  if (typeof value !== "string") {
    throw new ValidationError(`${label} must be a string`);
  }
  if (value.length > max) {
    throw new ValidationError(`${label} too long (max ${max})`);
  }
}

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
  // No `detail` to check: a caller cannot supply one. A resolver attaches it
  // after this guard has run, capped where it is built.
  return {
    images: garment.images.map((img) =>
      requireInlineImage(img, "garment image")
    ),
  };
}

/** Called by `runTryonJob`, so every caller (app, LIFF, LINE) is checked. */
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
    // ambient user config a client may send uniformly, dropped here so the job
    // runs on params that say what will actually happen. The engine survives —
    // nothing on this path reads it, but it names a model tier a video model
    // that grows tiers would need back.
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
