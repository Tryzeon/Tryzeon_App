export interface CatalogItem {
  productId: string;
  name: string;
  price: number | null;
  storeName: string | null;
  imageUrls: string[];
  purchaseLink: string | null;
}

/** 這份目錄所屬的店家。未指定店家的全站目錄為 null。 */
export interface CatalogStore {
  id: string;
  name: string;
}

export function publicImageUrl(baseUrl: string, key: string): string {
  return `${baseUrl.replace(/\/+$/, "")}/${key}`;
}

/**
 * 把一列 list_shop_products 的 jsonb 轉成目錄項目。
 *
 * 沒有可用圖片的商品仍然成為一個項目,只是 imageUrls 是空的。在這裡把它丟掉會
 * 讓 items.length 和分頁算術依據的列數對不起來,而且會讓商品從店家自己的目錄
 * 消失,而不是顯示出它缺照片。
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
