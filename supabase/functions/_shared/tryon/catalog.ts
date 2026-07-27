import { SupabaseClient } from "jsr:@supabase/supabase-js@2";
import { isUuid } from "../text.ts";
import { ValidationError } from "./errors.ts";
import { LIMITS } from "./types.ts";
import type { ResolvedGarment } from "./types.ts";

/** Raw product columns needed to build a try-on garment. */
export interface ProductGarmentRow {
  image_paths: unknown;
  name: unknown;
  material: unknown;
  fit: unknown;
  elasticity: unknown;
  thickness: unknown;
}

function trimmedString(value: unknown): string {
  return typeof value === "string" ? value.trim() : "";
}

/**
 * Model-facing garment description built from a product row. Mirrors the
 * retired client `toTryonPromptDetail()` so every surface produces the same
 * prompt. DB text already equals the enum values, so no remapping.
 */
export function buildProductGarmentDetail(
  row: ProductGarmentRow,
): string | undefined {
  const parts: string[] = [];
  const name = trimmedString(row.name);
  if (name) parts.push(`Product: ${name}`);
  const material = trimmedString(row.material);
  if (material) parts.push(`Material: ${material}`);
  const fit = trimmedString(row.fit);
  if (fit) parts.push(`Fit: ${fit}`);
  const elasticity = trimmedString(row.elasticity);
  if (elasticity) parts.push(`Elasticity: ${elasticity}`);
  const thickness = trimmedString(row.thickness);
  if (thickness) parts.push(`Thickness: ${thickness}`);
  if (parts.length === 0) return undefined;
  return parts.join(". ").slice(0, LIMITS.MAX_GARMENT_DETAIL_LENGTH);
}

/**
 * Resolves a client-supplied productId to trusted garment material by reading
 * the product from the catalog. The client never supplies a path, so it cannot
 * fetch arbitrary objects — only a real product's first image, plus a
 * server-built detail. Shared by every try-on adapter via the core.
 */
export async function resolveProductGarment(
  admin: SupabaseClient,
  productId: string,
): Promise<ResolvedGarment> {
  // Reject non-UUID ids up front so garbage yields a clean validation error
  // instead of a Postgres "invalid input syntax for type uuid".
  if (!isUuid(productId)) {
    throw new ValidationError(`invalid productId: ${productId}`);
  }

  const { data, error } = await admin
    .from("products")
    .select("image_paths, name, material, fit, elasticity, thickness")
    .eq("id", productId)
    .maybeSingle();

  if (error) {
    throw new Error(`product lookup failed: ${error.message}`);
  }
  if (!data) {
    throw new ValidationError(`no product for productId: ${productId}`);
  }

  const paths = (data.image_paths as string[] | null) ?? [];
  if (paths.length === 0) {
    throw new ValidationError(
      `no usable garment image for productId: ${productId}`,
    );
  }

  // Every image the limit allows, not just the first: the prompt treats a
  // garment's images as one group showing the same piece from several angles,
  // and a catalog product is the source most likely to actually have them.
  const images = paths
    .slice(0, LIMITS.MAX_IMAGES_PER_GARMENT)
    .map((path) => ({ path }));

  const detail = buildProductGarmentDetail(data as ProductGarmentRow);
  return detail === undefined ? { images } : { images, detail };
}
