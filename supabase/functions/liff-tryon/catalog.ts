import { SupabaseClient } from "jsr:@supabase/supabase-js@2";
import { ValidationError } from "./request.ts";

const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/**
 * Resolves a client-supplied productId to a trusted R2 garment key by reading
 * the product's image_paths from the DB. The client never supplies a path, so
 * it cannot fetch arbitrary objects — only a real product's first stores/ image.
 */
export async function resolveProductGarmentKey(
  admin: SupabaseClient,
  productId: string,
): Promise<string> {
  // Reject non-UUID ids up front so garbage input yields a clean 400 instead
  // of a Postgres "invalid input syntax for type uuid" error surfacing as 500.
  if (!UUID_RE.test(productId)) {
    throw new ValidationError(`invalid productId: ${productId}`);
  }

  const { data, error } = await admin
    .from("products")
    .select("image_paths")
    .eq("id", productId)
    .maybeSingle();

  if (error) {
    throw new Error(`product lookup failed: ${error.message}`);
  }

  const imagePaths: unknown = data?.image_paths;
  const key = Array.isArray(imagePaths)
    ? imagePaths.find((p) => typeof p === "string" && p.startsWith("stores/"))
    : undefined;

  if (!key) {
    throw new ValidationError(`no usable garment image for productId: ${productId}`);
  }
  return key as string;
}
