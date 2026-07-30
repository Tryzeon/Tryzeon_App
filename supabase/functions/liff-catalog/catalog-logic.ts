import { publicImageUrl } from "../_shared/storage.ts";

export interface CatalogSize {
  name: string;
  measurements: Record<string, unknown> | null;
}

export interface CatalogItem {
  productId: string;
  name: string;
  price: number | null;
  storeName: string | null;
  imageUrls: string[];
  purchaseLink: string | null;
  sizes: CatalogSize[];
}

function buildSizes(raw: unknown): CatalogSize[] {
  if (!Array.isArray(raw)) return [];
  return raw.flatMap((entry) => {
    const r = (entry ?? {}) as Record<string, unknown>;
    if (typeof r.name !== "string" || r.name.length === 0) return [];
    const m = r.measurements;
    const measurements = m !== null && typeof m === "object" && !Array.isArray(m)
      ? m as Record<string, unknown>
      : null;
    return [{ name: r.name, measurements }];
  });
}

/**
 * Maps a list_shop_products jsonb row to a catalog item, or null when the
 * product has no image to use as a garment reference.
 */
export function buildCatalogItem(row: unknown, baseUrl: string): CatalogItem | null {
  const r = (row ?? {}) as Record<string, unknown>;
  const keys = Array.isArray(r.image_paths)
    ? r.image_paths.filter((k): k is string => typeof k === "string" && k.length > 0)
    : [];
  if (keys.length === 0) return null;

  const store = (r.store_profiles ?? null) as Record<string, unknown> | null;
  const link = r.purchase_link;

  return {
    productId: String(r.id),
    name: typeof r.name === "string" ? r.name : "",
    price: typeof r.price === "number" ? r.price : null,
    storeName: store && typeof store.name === "string" ? store.name : null,
    imageUrls: keys.map((k) => publicImageUrl(baseUrl, k)),
    purchaseLink: typeof link === "string" && link.length > 0 ? link : null,
    sizes: buildSizes(r.product_sizes),
  };
}
