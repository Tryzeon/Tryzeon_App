import { isUuid } from "../text.ts";
import type { BodyMeasurements } from "../user-profile.ts";
import { buildGarmentFitDetail, type SizeMeasurements } from "./fit.ts";
import { ValidationError } from "./errors.ts";
import { LIMITS } from "./types.ts";
import type { ProductRef, ResolvedGarment } from "./types.ts";
import { asJsonObject, type DbClient } from "../supabase.ts";

const PRODUCT_SIZES_TABLE = "product_sizes";

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
 * `products.fit` is emitted as `Cut:`, not `Fit:`: it is a label derived from
 * the product photo (see `analyze-product-image`) describing the design
 * silhouette on a generic body, saying nothing about this wearer. It ships
 * alongside `buildGarmentFitDetail`'s ease numbers rather than being displaced
 * by them, and the prompt names which of the two governs tightness.
 */
export function buildProductGarmentDetail(
  row: ProductGarmentRow,
): string | undefined {
  const parts: string[] = [];
  const name = trimmedString(row.name);
  if (name) parts.push(`Product: ${name}`);
  const material = trimmedString(row.material);
  if (material) parts.push(`Material: ${material}`);
  const cut = trimmedString(row.fit);
  if (cut) parts.push(`Cut: ${cut}`);
  const elasticity = trimmedString(row.elasticity);
  if (elasticity) parts.push(`Elasticity: ${elasticity}`);
  const thickness = trimmedString(row.thickness);
  if (thickness) parts.push(`Thickness: ${thickness}`);
  if (parts.length === 0) return undefined;
  return parts.join(". ").slice(0, LIMITS.MAX_GARMENT_DETAIL_LENGTH);
}

/**
 * Bound by BOTH `id` and `product_id`, so a client-supplied sizeId can only
 * ever name a size of the product it is trying on.
 *
 * Neither a missing row nor a failed read is an error: the size may have been
 * deleted since the client read the catalog, and failing a generation that has
 * already been charged over a prompt enhancement would be the wrong trade.
 */
async function resolveSizeFit(
  client: DbClient,
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

export async function resolveProductGarment(
  client: DbClient,
  ref: ProductRef,
  body: BodyMeasurements | null,
): Promise<ResolvedGarment> {
  const { productId } = ref;
  // Reject non-UUID ids up front so garbage yields a clean validation error
  // instead of a Postgres "invalid input syntax for type uuid".
  if (!isUuid(productId)) {
    throw new ValidationError(`invalid productId: ${productId}`);
  }
  // Checked here rather than where it is used: gating it on whether the shopper
  // happens to have measurements would report the caller bug to some users and
  // swallow it for the rest.
  if (ref.sizeId !== undefined && !isUuid(ref.sizeId)) {
    throw new ValidationError(`invalid sizeId: ${ref.sizeId}`);
  }

  const { data, error } = await client.rpc("get_shop_product", {
    p_id: productId,
  });

  if (error) {
    throw new Error(`product lookup failed: ${error.message}`);
  }
  const row = asJsonObject<ProductGarmentRow>(data);
  if (!row) {
    throw new ValidationError(`no product for productId: ${productId}`);
  }

  const paths = (row.image_paths as string[] | null) ?? [];
  if (paths.length === 0) {
    throw new ValidationError(
      `no usable garment image for productId: ${productId}`,
    );
  }

  // The main shot only: a store's later images are detail macros carrying no
  // garment silhouette, and passing them off as extra angles dilutes the person
  // photo instead of describing the garment.
  const images = [{ path: paths[0] }];

  const detail = buildProductGarmentDetail(row);
  const fit = ref.sizeId && body
    ? await resolveSizeFit(client, productId, ref.sizeId, body)
    : undefined;

  const garment: ResolvedGarment = { images };
  if (detail !== undefined) garment.detail = detail;
  if (fit !== undefined) garment.fit = fit;
  return garment;
}
