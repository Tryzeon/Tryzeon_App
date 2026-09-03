import { fetchImageAsBase64 } from "../image-utils.ts";
import type { SupabaseImageBucket } from "../storage.ts";
import type { ImageSource, ResolvedGarment } from "./types.ts";
import type { DbClient } from "../supabase.ts";

export type SourceLoader = (source: ImageSource) => Promise<string>;

/**
 * `path` is routed by `fetchImageAsBase64`: R2 for 'stores/' keys, else the
 * given Supabase `bucket` — so a caller loading avatars and wardrobe garments
 * needs one loader per bucket.
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

export function loadGarments(
  garments: ResolvedGarment[],
  load: SourceLoader,
): Promise<string[][]> {
  return Promise.all(
    garments.map((garment) => Promise.all(garment.images.map(load))),
  );
}
