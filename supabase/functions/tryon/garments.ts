import { SupabaseClient } from "jsr:@supabase/supabase-js@2";
import { fetchImageAsBase64 } from "../_shared/image-utils.ts";
import { ValidationError, type GarmentInput, type ImageSource } from "./request.ts";

export type SourceResolver = (source: ImageSource) => Promise<string>;

/**
 * Builds the resolver backed by Supabase storage / R2. `path` is routed by
 * `fetchImageAsBase64` (R2 'stores/' keys vs Supabase buckets); `base64` is
 * passed through.
 */
export function makeSourceResolver(userClient: SupabaseClient): SourceResolver {
  return (source: ImageSource): Promise<string> => {
    if (source.base64) return Promise.resolve(source.base64);
    if (source.path) return fetchImageAsBase64(userClient, source.path);
    throw new ValidationError("image source has no usable key");
  };
}

/** Flattens every garment's images to base64 (order preserved) + per-garment counts. */
export async function resolveGarments(
  garments: GarmentInput[],
  resolver: SourceResolver,
): Promise<{ clothesBase64s: string[]; garmentImageCounts: number[] }> {
  const clothesBase64s: string[] = [];
  const garmentImageCounts: number[] = [];
  for (const garment of garments) {
    const resolved = await Promise.all(garment.images.map(resolver));
    clothesBase64s.push(...resolved);
    garmentImageCounts.push(resolved.length);
  }
  return { clothesBase64s, garmentImageCounts };
}
