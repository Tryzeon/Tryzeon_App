export interface CatalogItem {
  productId: string;
  name: string;
  price: number | null;
  storeName: string | null;
  imageUrl: string;
}

/**
 * Maps a list_shop_products jsonb row to a catalog item, or null when the
 * product has no R2-hosted (stores/) image to use as a garment reference.
 */
export function buildCatalogItem(row: unknown, baseUrl: string): CatalogItem | null {
  const r = (row ?? {}) as Record<string, unknown>;
  const imagePaths = Array.isArray(r.image_paths) ? r.image_paths : [];
  const key = imagePaths.find(
    (p): p is string => typeof p === "string" && p.startsWith("stores/"),
  );
  if (!key) return null;

  const base = baseUrl.replace(/\/+$/, "");
  const store = (r.store_profiles ?? null) as Record<string, unknown> | null;
  return {
    productId: String(r.id),
    name: typeof r.name === "string" ? r.name : "",
    price: typeof r.price === "number" ? r.price : null,
    storeName: store && typeof store.name === "string" ? store.name : null,
    imageUrl: `${base}/${key}`,
  };
}
