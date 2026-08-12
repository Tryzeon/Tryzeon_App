import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import type { SupabaseClient } from "jsr:@supabase/supabase-js@2";
import { getAdminClient } from "../_shared/supabase.ts";
import { json, jsonError, coreErrorResponse } from "../_shared/http.ts";
import { classifyCoreError } from "../_shared/errors.ts";
import { makeCors } from "../_shared/cors.ts";
import { buildCatalogItem } from "./catalog-logic.ts";
import { parseCatalogQuery } from "./query.ts";

const DEFAULT_LIMIT = 30;

const cors = makeCors({ methods: "GET" });

/**
 * 這份目錄屬於哪一家店,未指定店家時為 null。
 *
 * 每一頁都回傳,是為了讓呼叫端的店家身分獨立於 `items` —— 從商品列推導的話,一次
 * 沒有結果的搜尋就會讓店名消失。
 */
async function fetchStore(
  admin: SupabaseClient,
  storeId: string | null,
): Promise<{ id: string; name: string } | null> {
  if (storeId === null) return null;

  const { data, error } = await admin
    .from("store_profiles")
    .select("id, name")
    .eq("id", storeId)
    .maybeSingle();
  if (error) throw new Error(`store_profiles lookup failed: ${error.message}`);

  return data;
}

Deno.serve(async (req) => {
  const guarded = cors.guard(req);
  if (guarded) return guarded;

  try {
    const baseUrl = Deno.env.get("R2_PUBLIC_IMAGES_BASE_URL");
    if (!baseUrl) {
      return cors.wrap(jsonError("Server misconfigured", "INTERNAL_ERROR", 500));
    }

    const query = parseCatalogQuery(new URL(req.url));

    const admin = getAdminClient();
    // 兩筆查詢互不相依,並行才不會讓店家查詢多疊一次往返到目錄的延遲上。
    const [products, store] = await Promise.all([
      admin.rpc("list_shop_products", {
        p_store_id: query.storeId,
        p_search_query: query.searchQuery,
        p_sort_column: query.sortColumn,
        p_sort_ascending: query.sortAscending,
        p_limit: DEFAULT_LIMIT,
        p_offset: query.offset,
      }),
      fetchStore(admin, query.storeId),
    ]);
    if (products.error) {
      throw new Error(`list_shop_products failed: ${products.error.message}`);
    }

    const rows = Array.isArray(products.data) ? products.data : [];
    const items = rows
      .map((r) => buildCatalogItem(r, baseUrl))
      .filter((x) => x !== null);

    return cors.wrap(json({
      items,
      store,
      nextOffset: query.offset + rows.length,
      hasMore: rows.length === DEFAULT_LIMIT,
    }));
  } catch (err) {
    const info = classifyCoreError(err);
    if (info) return cors.wrap(coreErrorResponse(info));
    console.error("liff-catalog error:", err);
    return cors.wrap(jsonError("Internal server error", "INTERNAL_ERROR", 500));
  }
});
