/**
 * CORS for any edge function called from a browser.
 *
 * Origin is `*`. These functions authenticate from the request body or an
 * explicit header, never from cookies, so there is no credentialed request an
 * origin allowlist would be protecting — and `*` is incompatible with
 * credentials, which keeps that mistake unrepresentable rather than merely
 * unmade.
 *
 * Both halves are needed at every call site: `guard` answers the preflight and
 * rejects a method the function does not serve, `wrap` puts the headers on the
 * real response. CORS headers on a response the browser never receives —
 * because the preflight went unanswered — help no one.
 */
import { jsonError } from "./http.ts";

export type HttpMethod = "GET" | "POST" | "PUT" | "PATCH" | "DELETE";

/** Request headers a client may send unless the caller names its own set. */
const DEFAULT_ALLOW_HEADERS = ["Content-Type", "Authorization"] as const;

/** How long a browser may cache the preflight result. */
const MAX_AGE_SECONDS = 86400;

export interface CorsOptions {
  /**
   * The methods this function serves. OPTIONS is always allowed — it is the
   * preflight itself — so it is never listed here.
   */
  methods: HttpMethod | readonly HttpMethod[];
  /**
   * Overrides the request headers a client may send. Defaults to
   * `Content-Type, Authorization`, which covers a JSON body and a bearer token.
   */
  allowHeaders?: readonly string[];
}

export interface Cors {
  /**
   * Answers a preflight and rejects a method this function does not serve. A
   * non-null result is the response to return; null means the request may
   * proceed.
   */
  guard(req: Request): Response | null;
  /** Adds the CORS headers to an outgoing response. */
  wrap(resp: Response): Response;
}

export function makeCors(options: CorsOptions): Cors {
  const methods: readonly HttpMethod[] = typeof options.methods === "string"
    ? [options.methods]
    : options.methods;

  // Fixed for the lifetime of the function: nothing here reads per-request
  // state, so the headers are built once rather than on every response.
  const headers: Record<string, string> = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": [...methods, "OPTIONS"].join(", "),
    "Access-Control-Allow-Headers": (options.allowHeaders ?? DEFAULT_ALLOW_HEADERS)
      .join(", "),
    "Access-Control-Max-Age": String(MAX_AGE_SECONDS),
  };

  const wrap = (resp: Response): Response => {
    const merged = new Headers(resp.headers);
    for (const [k, v] of Object.entries(headers)) merged.set(k, v);
    return new Response(resp.body, { status: resp.status, headers: merged });
  };

  return {
    wrap,
    guard(req: Request): Response | null {
      if (req.method === "OPTIONS") {
        return new Response(null, { status: 204, headers });
      }
      if (!methods.includes(req.method as HttpMethod)) {
        return wrap(jsonError("Method not allowed", "METHOD_NOT_ALLOWED", 405));
      }
      return null;
    },
  };
}
