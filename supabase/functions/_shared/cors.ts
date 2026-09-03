/**
 * Origin is `*`. These functions authenticate from the request body or an
 * explicit header, never from cookies, so there is no credentialed request an
 * origin allowlist would be protecting — and `*` is incompatible with
 * credentials, which keeps that mistake unrepresentable rather than merely
 * unmade.
 */
import { jsonError } from "./http.ts";

export type HttpMethod = "GET" | "POST" | "PUT" | "PATCH" | "DELETE";

const DEFAULT_ALLOW_HEADERS = [
  "Content-Type",
  "Authorization",
  "apikey",
  "x-client-info",
] as const;

const MAX_AGE_SECONDS = 86400;

export interface CorsOptions {
  methods: HttpMethod | readonly HttpMethod[];
  allowHeaders?: readonly string[];
}

export interface Cors {
  guard(req: Request): Response | null;
  wrap(resp: Response): Response;
}

export function makeCors(options: CorsOptions): Cors {
  const methods: readonly HttpMethod[] = typeof options.methods === "string"
    ? [options.methods]
    : options.methods;

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
