import { fetchImageAsBase64 } from "../image-utils.ts";
import type { SupabaseImageBucket } from "../storage.ts";
import type { ImageSource, ResolvedGarment } from "./types.ts";
import type { DbClient } from "../supabase.ts";

/**
 * Loads one image source into the base64 bytes the model consumes. "Resolve"
 * is reserved for turning a garment ref (product or wardrobe) into material
 * (see `catalog.ts`, `wardrobe.ts`); everything in this module is the later
 * load stage.
 */
export type SourceLoader = (source: ImageSource) => Promise<string>;

/**
 * Builds the loader backed by Supabase storage / R2. `path` is routed by
 * `fetchImageAsBase64` (R2 'stores/' keys, else the given Supabase `bucket`);
 * `base64` is passed through. Callers loading different kinds of sources
 * (e.g. avatar vs. wardrobe garment) need one loader per bucket.
 */
export function makeSourceLoader(
  client: DbClient,
  bucket: SupabaseImageBucket,
): SourceLoader {
  return (source: ImageSource): Promise<string> =>
    "base64" in source
      ? Promise.resolve(source.base64)
      : fetchImageAsBase64(client, source.path, bucket);
}

/**
 * Loads every garment's images as base64, preserving garment grouping and
 * order. All sources load concurrently (one wave, not per-garment).
 */
export function loadGarments(
  garments: ResolvedGarment[],
  load: SourceLoader,
): Promise<string[][]> {
  return Promise.all(
    garments.map((garment) => Promise.all(garment.images.map(load))),
  );
}
