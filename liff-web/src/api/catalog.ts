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

async function requestCatalog(
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

// 第一頁在模組載入時就發出，跟 liff.init() 和首次 render 並行，不必等它們。
const prefetchStoreId = window.location.pathname.match(/^\/store\/([^/]+)/)?.[1];
let prefetched: Promise<CatalogPage> | null = requestCatalog({
  q: "",
  sort: "latest",
  offset: 0,
  storeId: prefetchStoreId,
});
// 抑制 unhandled rejection；真正的錯誤仍會交給取用它的呼叫端。
prefetched.catch(() => {});

/** 取一頁目錄。條件相符的第一次呼叫會直接接手啟動時預抓的那一頁。 */
export function fetchCatalog(query: CatalogQuery): Promise<CatalogPage> {
  const isPrefetched = query.q === "" &&
    query.sort === "latest" &&
    query.offset === 0 &&
    query.storeId === prefetchStoreId;
  if (prefetched === null || !isPrefetched) return requestCatalog(query);

  const page = prefetched;
  prefetched = null;
  return page;
}
