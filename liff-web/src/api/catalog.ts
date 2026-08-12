import { readJson } from "./errors";

export type SortOption = "latest" | "price_asc" | "price_desc";

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

export interface CatalogPage {
  items: CatalogItem[];
  store: CatalogStore | null;
  nextOffset: number;
  hasMore: boolean;
}

export interface CatalogQuery {
  q: string;
  sort: SortOption;
  offset: number;
  storeId?: string;
}

export async function fetchCatalog(
  { q, sort, offset, storeId }: CatalogQuery,
): Promise<CatalogPage> {
  const base = import.meta.env.VITE_LIFF_CATALOG_URL as string;
  const params = new URLSearchParams({ offset: String(offset), sort });
  if (q) params.set("q", q);
  if (storeId) params.set("store", storeId);

  const data = await readJson(await fetch(`${base}?${params}`));
  return {
    items: Array.isArray(data.items) ? (data.items as CatalogItem[]) : [],
    store: (data.store ?? null) as CatalogStore | null,
    nextOffset: typeof data.nextOffset === "number" ? data.nextOffset : offset,
    hasMore: Boolean(data.hasMore),
  };
}
