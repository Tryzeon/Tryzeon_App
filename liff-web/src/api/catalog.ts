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
 * Queried on every page so the store identity is independent of the items —
 * derived from the product rows, one empty search result would make the store
 * name disappear.
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
 * The catalog goes out as anon and does not wait for a session.
 *
 * The product catalog is public data anyway (both list_shop_products and
 * store_profiles are open to anon), and the prefetch fired at module load below
 * is part of the first-paint strategy — hanging it off the session would chain
 * it behind the auth round trip.
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

// The first page is requested at module load, in parallel with liff.init() and
// the first render rather than after them.
const prefetchStoreId = window.location.pathname.match(/^\/store\/([^/]+)/)?.[1];
let prefetched: Promise<CatalogPage> | null = requestCatalog({
  q: "",
  sort: "latest",
  offset: 0,
  storeId: prefetchStoreId,
});
// Suppress the unhandled rejection; the real error still reaches whichever
// caller consumes it.
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
 * Goes through `get_shop_product` instead of querying products directly: the
 * rule for "a product a customer may see" (`status = 'active'`) lives in that
 * function's body and should not be copied into the client a second time.
 */
export async function fetchProduct(productId: string): Promise<CatalogItem | null> {
  const id = normalizeUuid(productId);
  if (id === null) return null;

  const { data, error } = await supabase.rpc("get_shop_product", { p_id: id });
  if (error) throw error;
  return data === null ? null : buildCatalogItem(data, IMAGES_BASE_URL);
}
