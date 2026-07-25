import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { getAdminClient } from "../_shared/supabase.ts";
import { json, jsonError } from "../_shared/http.ts";
import { makeCors } from "../_shared/cors.ts";
import { buildCatalogItem } from "./catalog-logic.ts";

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

    const url = new URL(req.url);
    const offset = Math.max(0, parseInt(url.searchParams.get("offset") ?? "0", 10) || 0);

    const admin = getAdminClient();
    const { data, error } = await admin.rpc("list_shop_products", {
      p_limit: DEFAULT_LIMIT,
      p_offset: offset,
    });
    if (error) throw new Error(`list_shop_products failed: ${error.message}`);

    const rows = Array.isArray(data) ? data : [];
    const items = rows
      .map((r) => buildCatalogItem(r, baseUrl))
      .filter((x) => x !== null);

    return cors.wrap(
      json({ items, nextOffset: offset + rows.length, hasMore: rows.length === DEFAULT_LIMIT }),
    );
  } catch (err) {
    console.error("liff-catalog error:", err);
    return cors.wrap(jsonError("Internal server error", "INTERNAL_ERROR", 500));
  }
});
