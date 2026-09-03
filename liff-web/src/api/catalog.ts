import { supabase } from "../lib/supabase";
import {
  normalizeUuid,
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

/**
 * 走 `get_shop_product` 而不是自己查 products:「顧客看得到的商品」這條規則
 * (`status = 'active'`)在那支函式的身體裡,不該再被 client 抄一次。它回的欄位
 * 和目錄那支對得起來,所以共用同一個 `buildCatalogItem`。
 */
export async function fetchProduct(productId: string): Promise<CatalogItem | null> {
  const id = normalizeUuid(productId);
  if (id === null) return null;

  const { data, error } = await supabase.rpc("get_shop_product", { p_id: id });
  if (error) throw error;
  return data === null ? null : buildCatalogItem(data, IMAGES_BASE_URL);
}
