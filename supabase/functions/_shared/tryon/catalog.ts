import { SupabaseClient } from "jsr:@supabase/supabase-js@2";
import { isUuid } from "../text.ts";
import type { BodyMeasurements } from "../user-profile.ts";
import { buildGarmentFitDetail, type SizeMeasurements } from "./fit.ts";
import { ValidationError } from "./errors.ts";
import { LIMITS } from "./types.ts";
import type { ProductRef, ResolvedGarment } from "./types.ts";

const PRODUCTS_TABLE = "products";
const PRODUCT_SIZES_TABLE = "product_sizes";

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
 * The fit description for one published size, or undefined when there is
 * nothing trustworthy to say.
 *
 * Bound by BOTH `id` and `product_id`, so a client-supplied sizeId can only
 * ever name a size of the product it is trying on.
 *
 * Neither a missing row nor a failed read is an error: the size may have been
 * deleted between the client reading the catalog and sending the request, and
 * the fit sentence is a prompt enhancement — failing a generation that has
 * already been charged over either would be the wrong trade. A malformed id is
 * a caller bug and does raise, from `resolveProductGarment`.
 */
async function resolveSizeFit(
  client: SupabaseClient,
  productId: string,
  sizeId: string,
  body: BodyMeasurements,
): Promise<string | undefined> {
  const { data, error } = await client
    .from(PRODUCT_SIZES_TABLE)
    .select("name, measurements")
    .eq("id", sizeId)
    .eq("product_id", productId)
    .maybeSingle();

  if (error) {
    console.warn(
      `${PRODUCT_SIZES_TABLE} lookup failed for sizeId ${sizeId}; skipping fit detail: ${error.message}`,
    );
    return undefined;
  }
  if (!data) {
    console.warn(
      `no ${PRODUCT_SIZES_TABLE} row for sizeId ${sizeId} on product ${productId}; skipping fit detail`,
    );
    return undefined;
  }

  return buildGarmentFitDetail(
    typeof data.name === "string" ? data.name : "",
    (data.measurements as SizeMeasurements | null) ?? null,
    body,
  );
}

/**
 * Resolves a client-supplied productId to trusted garment material by reading
 * the product from the catalog. The client never supplies a path, so it cannot
 * fetch arbitrary objects — only a real product's images, plus a
 * server-built detail. Shared by every try-on adapter via the core.
 */
export async function resolveProductGarment(
  client: SupabaseClient,
  ref: ProductRef,
  body: BodyMeasurements | null,
): Promise<ResolvedGarment> {
  const { productId } = ref;
  // Reject non-UUID ids up front so garbage yields a clean validation error
  // instead of a Postgres "invalid input syntax for type uuid".
  if (!isUuid(productId)) {
    throw new ValidationError(`invalid productId: ${productId}`);
  }
  // Checked here rather than where it is used: gating this on whether the
  // shopper happens to have measurements would report the caller bug to some
  // users and swallow it for the rest.
  if (ref.sizeId !== undefined && !isUuid(ref.sizeId)) {
    throw new ValidationError(`invalid sizeId: ${ref.sizeId}`);
  }

  const { data, error } = await client
    .from(PRODUCTS_TABLE)
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
  const fit = ref.sizeId && body
    ? await resolveSizeFit(client, productId, ref.sizeId, body)
    : undefined;

  const garment: ResolvedGarment = { images };
  if (detail !== undefined) garment.detail = detail;
  if (fit !== undefined) garment.fit = fit;
  return garment;
}
