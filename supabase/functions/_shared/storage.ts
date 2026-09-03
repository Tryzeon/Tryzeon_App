/**
 * An image referenced by a bare path can live in one of two backends:
 *   - Cloudflare R2 public bucket — keys namespaced with `stores/` (store logos
 *     and product images). This prefix is a leading, distinct namespace and can
 *     never collide with the user-scoped Supabase paths below (those start with
 *     a user UUID), so it is a safe discriminator.
 *   - Supabase Storage — the bucket CANNOT be inferred from the path (wardrobe
 *     item keys are `{userId}/{category}/{fileName}`, with no reliable folder
 *     name), so callers must name the bucket explicitly based on the image's
 *     semantic role (avatar vs. wardrobe garment).
 */

export const R2_PUBLIC_PREFIX = "stores/";

export const USER_AVATARS_BUCKET = "user-avatars";

export const WARDROBE_IMAGES_BUCKET = "wardrobe-images";

export type SupabaseImageBucket =
  | typeof USER_AVATARS_BUCKET
  | typeof WARDROBE_IMAGES_BUCKET;

export function isR2PublicKey(path: string): boolean {
  return path.startsWith(R2_PUBLIC_PREFIX);
}

export function publicImageUrl(baseUrl: string, key: string): string {
  return `${baseUrl.replace(/\/+$/, "")}/${key}`;
}
