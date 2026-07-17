import { LIMITS, ValidationError } from "./types.ts";
import type { GarmentInput, ImageSource, TryonParams } from "./types.ts";

/** Coerce an unknown value into an ImageSource with exactly one usable key. */
function normalizeSource(source: unknown, label: string): ImageSource {
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

function normalizeDetail(detail: unknown): string | undefined {
  if (typeof detail !== "string") return undefined;
  const trimmed = detail.trim();
  if (trimmed.length === 0) return undefined;
  return trimmed.slice(0, LIMITS.MAX_GARMENT_DETAIL_LENGTH);
}

/**
 * Assert the lib's domain invariants on an already-typed params object.
 * Called by runTryonJob so every caller (app, LIFF, LINE) is guarded uniformly.
 */
export function assertTryonParams(params: TryonParams): void {
  normalizeSource(params.avatar, "avatar");

  if (!Array.isArray(params.garments) || params.garments.length === 0) {
    throw new ValidationError("garments must be a non-empty array");
  }
  if (params.garments.length > LIMITS.MAX_GARMENTS) {
    throw new ValidationError(`too many garments (max ${LIMITS.MAX_GARMENTS})`);
  }
  for (const garment of params.garments) {
    if (
      typeof garment !== "object" || garment === null ||
      !Array.isArray(garment.images) || garment.images.length === 0
    ) {
      throw new ValidationError("each garment must have a non-empty images array");
    }
    if (garment.images.length > LIMITS.MAX_IMAGES_PER_GARMENT) {
      throw new ValidationError(
        `too many images for a garment (max ${LIMITS.MAX_IMAGES_PER_GARMENT})`,
      );
    }
    for (const img of garment.images) {
      normalizeSource(img, "garment image");
    }
    if (garment.detail !== undefined && typeof garment.detail !== "string") {
      throw new ValidationError("garment detail must be a string");
    }
  }

  if (params.mode !== "image" && params.mode !== "video") {
    throw new ValidationError("mode must be 'image' or 'video'");
  }
}

/**
 * Parse an unknown wire body into validated TryonParams, attaching the
 * caller-supplied (authenticated) userId. Used by the app entry point to turn
 * JSON into params with clean 400s.
 */
export function parseTryonParams(body: unknown, userId: string): TryonParams {
  if (typeof body !== "object" || body === null) {
    throw new ValidationError("body must be an object");
  }
  const b = body as Record<string, unknown>;

  const avatar = normalizeSource(b.avatar, "avatar");

  if (!Array.isArray(b.garments) || b.garments.length === 0) {
    throw new ValidationError("garments must be a non-empty array");
  }
  const garments: GarmentInput[] = (b.garments as unknown[]).map((rg) => {
    if (typeof rg !== "object" || rg === null) {
      throw new ValidationError("each garment must be an object");
    }
    const imagesRaw = (rg as Record<string, unknown>).images;
    if (!Array.isArray(imagesRaw) || imagesRaw.length === 0) {
      throw new ValidationError("each garment must have a non-empty images array");
    }
    const images = imagesRaw.map((img) => normalizeSource(img, "garment image"));
    const detail = normalizeDetail((rg as Record<string, unknown>).detail);
    return detail === undefined ? { images } : { images, detail };
  });

  const mode = b.mode === "video" ? "video" : "image";

  const params: TryonParams = {
    userId,
    avatar,
    garments,
    mode,
    scenePrompt: typeof b.scenePrompt === "string" ? b.scenePrompt : undefined,
    transitionPrompt: typeof b.transitionPrompt === "string"
      ? b.transitionPrompt
      : undefined,
  };
  assertTryonParams(params);
  return params;
}
