import type { ImageSource, GarmentInput } from "../_shared/tryon-sources.ts";

export const LIMITS = {
  MAX_GARMENTS: 3,
  MAX_IMAGES_PER_GARMENT: 3,
} as const;

export class ValidationError extends Error {}

export interface TryonRequest {
  avatar: ImageSource;
  garments: GarmentInput[];
  mode: "image" | "video";
  scenePrompt?: string;
  transitionPrompt?: string;
}

function assertSingleSourceKey(source: unknown, label: string): ImageSource {
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

export function parseTryonRequest(body: unknown): TryonRequest {
  if (typeof body !== "object" || body === null) {
    throw new ValidationError("body must be an object");
  }
  const b = body as Record<string, unknown>;

  const avatar = assertSingleSourceKey(b.avatar, "avatar");

  if (!Array.isArray(b.garments) || b.garments.length === 0) {
    throw new ValidationError("garments must be a non-empty array");
  }
  if (b.garments.length > LIMITS.MAX_GARMENTS) {
    throw new ValidationError(`too many garments (max ${LIMITS.MAX_GARMENTS})`);
  }
  const garments: GarmentInput[] = (b.garments as unknown[]).map((rg) => {
    if (typeof rg !== "object" || rg === null) {
      throw new ValidationError("each garment must be an object");
    }
    const imagesRaw = (rg as Record<string, unknown>).images;
    if (!Array.isArray(imagesRaw) || imagesRaw.length === 0) {
      throw new ValidationError("each garment must have a non-empty images array");
    }
    if (imagesRaw.length > LIMITS.MAX_IMAGES_PER_GARMENT) {
      throw new ValidationError(
        `too many images for a garment (max ${LIMITS.MAX_IMAGES_PER_GARMENT})`,
      );
    }
    const images = imagesRaw.map((img) => assertSingleSourceKey(img, "garment image"));
    return { images };
  });

  const mode = b.mode === "video" ? "video" : "image";

  return {
    avatar,
    garments,
    mode,
    scenePrompt: typeof b.scenePrompt === "string" ? b.scenePrompt : undefined,
    transitionPrompt: typeof b.transitionPrompt === "string" ? b.transitionPrompt : undefined,
  };
}
