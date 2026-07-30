import { publicImageUrl } from "../_shared/storage.ts";

export interface CatalogItem {
  productId: string;
  name: string;
  price: number | null;
  storeName: string | null;
  imageUrls: string[];
  purchaseLink: string | null;
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
  };
}
