import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { getAdminClient } from "../_shared/supabase.ts";

// ── Configuration ──────────────────────────────────────────────────────────

// Where to send desktop / fallback traffic when a code has no platform link.
const WEB_BASE_URL = Deno.env.get("WEB_BASE_URL") ?? "https://tryzeon.com";

// ── Helpers ──────────────────────────────────────────────────────────────────

/** Best-effort platform from the User-Agent. */
function platformFromUserAgent(ua: string | null): string {
  if (!ua) return "other";
  if (/android/i.test(ua)) return "android";
  if (/iphone|ipad|ipod/i.test(ua)) return "ios";
  return "other";
}

/**
 * The code is the last path segment. The site redirects
 * tryzeon.com/s/{code} -> .../functions/v1/resolve-link/{code}.
 */
function codeFromRequest(url: URL): string | null {
  const segments = url.pathname.split("/").filter(Boolean);
  return segments.length > 0 ? segments[segments.length - 1] : null;
}

function redirect(location: string): Response {
  return new Response(null, { status: 302, headers: { Location: location } });
}

// ── Handler ──────────────────────────────────────────────────────────────────

Deno.serve(async (req) => {
  try {
    const url = new URL(req.url);
    const code = codeFromRequest(url);

    if (!code) {
      return redirect(WEB_BASE_URL);
    }

    const adminClient = getAdminClient();

    const { data: link, error } = await adminClient
      .from("short_links")
      .select("code, target_type, target_id, forward_url, is_active")
      .eq("code", code)
      .eq("is_active", true)
      .maybeSingle();

    if (error) {
      console.error("resolve-link lookup failed:", error);
      return redirect(WEB_BASE_URL);
    }

    if (!link) {
      console.warn(`resolve-link: unknown or inactive code "${code}"`);
      return redirect(WEB_BASE_URL);
    }

    // Log the anonymous (not-installed) open.
    const platform = platformFromUserAgent(req.headers.get("User-Agent"));
    const { error: insertError } = await adminClient.from("link_events").insert({
      code: link.code,
      source: "web",
      platform,
    });

    if (insertError) {
      // Never block the redirect on a logging failure — log and continue.
      console.error("resolve-link: failed to record open:", insertError);
    }

    // Forward to the platform link for deferred deep linking. Falls back to the
    // web destination so desktop / mis-configured codes still land somewhere.
    if (link.forward_url) {
      return redirect(link.forward_url);
    }
    return redirect(`${WEB_BASE_URL}/${link.target_type}/${link.target_id}`);
  } catch (err) {
    console.error("resolve-link handler error:", err);
    return redirect(WEB_BASE_URL);
  }
});
