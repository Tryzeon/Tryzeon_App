import { supabase } from "../lib/supabase";
import {
  parseStoreId,
  searchParam,
  sortParams,
  type SortOption,
} from "./catalog-query";
import {
  buildCatalogItem,
  type CatalogItem,
  type CatalogStore,
} from "./catalog-row";

export type { CatalogItem, CatalogStore, SortOption };

const PAGE_SIZE = 30;
const IMAGES_BASE_URL = import.meta.env.VITE_R2_PUBLIC_IMAGES_BASE_URL as string;

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

/**
 * 這份目錄屬於哪一家店,未指定店家時為 null。
 *
 * 每一頁都查一次,是為了讓店家身分獨立於 items —— 從商品列推導的話,一次沒有
 * 結果的搜尋就會讓店名消失。
 */
async function fetchStore(storeId: string | null): Promise<CatalogStore | null> {
  if (storeId === null) return null;

  const { data, error } = await supabase
    .from("store_profiles")
    .select("id, name")
    .eq("id", storeId)
    .maybeSingle();
  if (error) throw error;

  return data;
}

/**
 * 目錄走 anon,不等 session。
 *
 * 商品目錄本來就是公開資料(list_shop_products 與 store_profiles 都對 anon 開
 * 放),而下面那個 module load 時就發出的預抓是首屏策略的一部分 —— 掛到 session
 * 後面就等於把它串到 auth 的來回之後。
 */
async function requestCatalog(
  { q, sort, offset, storeId }: CatalogQuery,
): Promise<CatalogPage> {
  const store = parseStoreId(storeId);
  const { sortColumn, sortAscending } = sortParams(sort);

  // 兩筆查詢互不相依,並行才不會讓店家查詢多疊一次往返到目錄的延遲上。
  // 多取一列就知道還有沒有下一頁,不必再問一次 count。
  const [products, storeProfile] = await Promise.all([
    supabase.rpc("list_shop_products", {
      p_store_id: store,
      p_search_query: searchParam(q),
      p_sort_column: sortColumn,
      p_sort_ascending: sortAscending,
      p_limit: PAGE_SIZE + 1,
      p_offset: offset,
    }),
    fetchStore(store),
  ]);
  if (products.error) throw products.error;

  const fetched = Array.isArray(products.data) ? products.data : [];
  const hasMore = fetched.length > PAGE_SIZE;
  const rows = hasMore ? fetched.slice(0, PAGE_SIZE) : fetched;

  return {
    items: rows.map((r) => buildCatalogItem(r, IMAGES_BASE_URL)),
    store: storeProfile,
    nextOffset: offset + rows.length,
    hasMore,
  };
}

// 第一頁在模組載入時就發出,跟 liff.init() 和首次 render 並行,不必等它們。
const prefetchStoreId = window.location.pathname.match(/^\/store\/([^/]+)/)?.[1];
let prefetched: Promise<CatalogPage> | null = requestCatalog({
  q: "",
  sort: "latest",
  offset: 0,
  storeId: prefetchStoreId,
});
// 抑制 unhandled rejection;真正的錯誤仍會交給取用它的呼叫端。
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
