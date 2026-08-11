import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { getAdminClient } from "../_shared/supabase.ts";
import { json, jsonError, coreErrorResponse } from "../_shared/http.ts";
import { classifyCoreError } from "../_shared/errors.ts";
import { makeCors } from "../_shared/cors.ts";
import { buildCatalogItem } from "./catalog-logic.ts";
import { parseCatalogQuery } from "./query.ts";

const DEFAULT_LIMIT = 30;

const cors = makeCors({ methods: "GET" });

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
    const { data, error } = await admin.rpc("list_shop_products", {
      p_store_id: query.storeId,
      p_search_query: query.searchQuery,
      p_sort_column: query.sortColumn,
      p_sort_ascending: query.sortAscending,
      p_limit: DEFAULT_LIMIT,
      p_offset: query.offset,
    });
    if (error) throw new Error(`list_shop_products failed: ${error.message}`);

    const rows = Array.isArray(data) ? data : [];
    const items = rows
      .map((r) => buildCatalogItem(r, baseUrl))
      .filter((x) => x !== null);

    return cors.wrap(json({
      items,
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
