import { publicImageUrl } from "../_shared/storage.ts";

export interface CatalogItem {
  productId: string;
  name: string;
  price: number | null;
  storeName: string | null;
  imageUrl: string;
}

/**
 * Maps a list_shop_products jsonb row to a catalog item, or null when the
 * product has no image to use as a garment reference.
 */
export function buildCatalogItem(row: unknown, baseUrl: string): CatalogItem | null {
  const r = (row ?? {}) as Record<string, unknown>;
  const key = (r.image_paths as string[] | null)?.[0];
  if (!key) return null;

  const store = (r.store_profiles ?? null) as Record<string, unknown> | null;
  return {
    productId: String(r.id),
    name: typeof r.name === "string" ? r.name : "",
    price: typeof r.price === "number" ? r.price : null,
    storeName: store && typeof store.name === "string" ? store.name : null,
    imageUrl: publicImageUrl(baseUrl, key),
  };
}
