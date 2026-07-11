import { SupabaseClient } from "jsr:@supabase/supabase-js@2";
import { fetchImageAsBase64 } from "./image-utils.ts";

export class ValidationError extends Error {}

export interface ImageSource {
  path?: string;
  base64?: string;
}

export interface GarmentInput {
  images: ImageSource[];
}

export type SourceResolver = (source: ImageSource) => Promise<string>;

/**
 * Builds the resolver backed by Supabase storage / R2. `path` is routed by
 * `fetchImageAsBase64` (R2 'stores/' keys, else the given Supabase `bucket`);
 * `base64` is passed through. Callers resolving different kinds of sources
 * (e.g. avatar vs. wardrobe garment) need separate resolvers, one per bucket.
 */
export function makeSourceResolver(client: SupabaseClient, bucket: string): SourceResolver {
  return (source: ImageSource): Promise<string> => {
    if (source.base64) return Promise.resolve(source.base64);
    if (source.path) return fetchImageAsBase64(client, source.path, bucket);
    throw new ValidationError("image source has no usable key");
  };
}

/**
 * Resolves every garment's images to base64, preserving garment grouping and
 * order. All sources resolve concurrently (one wave, not per-garment).
 */
export function resolveGarments(
  garments: GarmentInput[],
  resolver: SourceResolver,
): Promise<string[][]> {
  return Promise.all(
    garments.map((garment) => Promise.all(garment.images.map(resolver))),
  );
}
