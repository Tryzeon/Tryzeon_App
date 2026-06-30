import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { getAdminClient } from "../_shared/supabase.ts";
import { json, jsonError } from "../_shared/http.ts";
import { buildCatalogItem } from "./catalog-logic.ts";

const DEFAULT_LIMIT = 30;

function corsHeaders(): Record<string, string> {
  const origin = Deno.env.get("LIFF_WEB_ORIGIN") ?? "*";
  return {
    "Access-Control-Allow-Origin": origin,
    "Access-Control-Allow-Methods": "GET, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type",
  };
}

function withCors(resp: Response): Response {
  const headers = new Headers(resp.headers);
  for (const [k, v] of Object.entries(corsHeaders())) headers.set(k, v);
  return new Response(resp.body, { status: resp.status, headers });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders() });
  }
  if (req.method !== "GET") {
    return withCors(jsonError("Method not allowed", "METHOD_NOT_ALLOWED", 405));
  }

  try {
    const baseUrl = Deno.env.get("R2_PUBLIC_IMAGES_BASE_URL");
    if (!baseUrl) {
      return withCors(jsonError("Server misconfigured", "INTERNAL_ERROR", 500));
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

    return withCors(
      json({ items, nextOffset: offset + rows.length, hasMore: rows.length === DEFAULT_LIMIT }),
    );
  } catch (err) {
    console.error("liff-catalog error:", err);
    return withCors(jsonError("Internal server error", "INTERNAL_ERROR", 500));
  }
});
