import "jsr:@supabase/functions-js@^2.113.0/edge-runtime.d.ts";
import { type DbClient, getAnonClient } from "../_shared/supabase.ts";
import { publicImageUrl } from "../_shared/storage.ts";
import { json, jsonError } from "../_shared/http.ts";
import {
  channelFromUserAgent,
  codeFromPathname,
  detectSurface,
  platformFromUserAgent,
  type Surface,
} from "./surface.ts";
import { buildStoreDestination, deliveryFor, isOpenWith } from "./destination.ts";

declare const EdgeRuntime: { waitUntil(p: Promise<unknown>): void } | undefined;

/**
 * Config each open method needs. Deliberately not checked at startup: a missing
 * LIFF_URL should only fail liff-type links, not the whole function — web-type
 * links, added later, must work without this setting.
 */
const DESTINATION_CONFIG = {
  liffUrl: Deno.env.get("LIFF_URL") ?? null,
};

const IMAGES_BASE_URL = Deno.env.get("R2_PUBLIC_IMAGES_BASE_URL") ?? null;

/** Catches its own errors: running inside `EdgeRuntime.waitUntil`, a background
 * task's rejection has nobody to handle it. */
async function recordOpen(
  client: DbClient,
  code: string,
  surface: Surface,
  userAgent: string | null,
): Promise<void> {
  try {
    const { error } = await client.from("link_events").insert({
      code,
      source: surface,
      platform: platformFromUserAgent(userAgent),
      channel: channelFromUserAgent(userAgent),
    });
    if (error) {
      console.error("short-links: failed to record open:", error);
    }
  } catch (err) {
    console.error("short-links: failed to record open:", err);
  }
}

/** Always no-store — every call records an open event, so callers must not cache
 * this endpoint. */
function noStore(response: Response): Response {
  const headers = new Headers(response.headers);
  headers.set("Cache-Control", "no-store");
  return new Response(response.body, { status: response.status, headers });
}

/**
 * The status codes carry meaning: 404 is "this code does not exist or is
 * disabled", 5xx is "we are broken". Callers currently send both to the site's
 * home page, but the distinction stays in the protocol because the two deserve
 * different wording — calling an outage an expired link tells a store's customer
 * their standee is useless.
 */
Deno.serve(async (req) => {
  try {
    const code = codeFromPathname(new URL(req.url).pathname);
    if (!code) {
      return noStore(jsonError("Malformed code", "NOT_FOUND", 404));
    }

    // anon is enough: the `short_links` select policy only exposes is_active
    // rows, `store_profiles` is publicly readable anyway, and `link_events` has
    // an anonymous insert policy. This endpoint is callable by anyone, so there
    // is no reason for it to hold a service role key.
    const client = getAnonClient();
    const { data: link, error } = await client
      .from("short_links")
      .select("code, store_id, open_with, store_profiles!inner(name, logo_path)")
      .eq("code", code)
      .eq("is_active", true)
      .maybeSingle();

    if (error) {
      console.error("short-links lookup failed:", error);
      return noStore(jsonError("Lookup failed", "INTERNAL_ERROR", 500));
    }
    if (!link) {
      console.warn(`short-links: unknown or inactive code "${code}"`);
      return noStore(jsonError("Unknown or inactive code", "NOT_FOUND", 404));
    }

    // The DB check constraint only allows implemented values, so reaching here
    // means the schema and the code are out of sync.
    if (!isOpenWith(link.open_with)) {
      console.error(`short-links: unsupported open_with "${link.open_with}" on "${link.code}"`);
      return noStore(jsonError("Unsupported link target", "INTERNAL_ERROR", 500));
    }

    const url = buildStoreDestination(link.open_with, link.store_id, DESTINATION_CONFIG);
    if (url === null) {
      console.error(`short-links: missing config for open_with "${link.open_with}"`);
      return noStore(jsonError("Server misconfigured", "INTERNAL_ERROR", 500));
    }

    // Typed as an object for a to-one `!inner` relation, but depending on the
    // PostgREST version it can come back as a single-element array, so the shape
    // is still narrowed once at runtime.
    const embedded = link.store_profiles;
    const store = Array.isArray(embedded) ? embedded[0] ?? null : embedded;

    const userAgent = req.headers.get("User-Agent");
    const surface = detectSurface(userAgent);

    // Whoever scanned the code should not wait for the event write before being
    // redirected: measured, this write is about half the hot-path response time
    // (~0.45s, a second PostgREST round trip).
    const record = recordOpen(client, link.code, surface, userAgent);
    if (typeof EdgeRuntime !== "undefined") EdgeRuntime.waitUntil(record);
    else await record;

    return noStore(json({
      url,
      delivery: deliveryFor(link.open_with, surface),
      store: {
        name: store?.name ?? null,
        logoUrl: store?.logo_path && IMAGES_BASE_URL
          ? publicImageUrl(IMAGES_BASE_URL, store.logo_path)
          : null,
      },
    }));
  } catch (err) {
    console.error("short-links handler error:", err);
    return noStore(jsonError("Internal server error", "INTERNAL_ERROR", 500));
  }
});
