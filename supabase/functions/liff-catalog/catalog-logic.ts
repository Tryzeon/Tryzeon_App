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
 * Maps a list_shop_products jsonb row to a catalog item.
 *
 * A product with no usable image still becomes an item, with `imageUrls` empty.
 * Dropping it here made `items.length` disagree with the row count the paging
 * arithmetic is built on, and hid the product from the store's own catalog
 * instead of showing that its photo is missing.
 */
export function buildCatalogItem(row: unknown, baseUrl: string): CatalogItem {
  const r = (row ?? {}) as Record<string, unknown>;
  const keys = Array.isArray(r.image_paths)
    ? r.image_paths.filter((k): k is string => typeof k === "string" && k.length > 0)
    : [];

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
