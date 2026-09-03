// Shared JSON HTTP response helpers for Edge Functions.
import { CORE_ERROR_CODE, type CoreErrorInfo } from "./errors.ts";

const JSON_HEADERS = { "Content-Type": "application/json" } as const;

export function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), { status, headers: JSON_HEADERS });
}

export function jsonError(message: string, code: string, status: number): Response {
  return json({ error: message, code }, status);
}

/**
 * The standard 429 rate-limit response — a `jsonError` with its message, code
 * and status fixed, so every rate-limited endpoint answers identically. Pass
 * `usage` to include quota details.
 */
export function jsonRateLimited(usage?: unknown): Response {
  const code = CORE_ERROR_CODE.quota;
  return json(
    usage === undefined
      ? { error: "Rate limit exceeded", code }
      : { error: "Rate limit exceeded", code, usage },
    429,
  );
}

/**
 * The canonical HTTP rendering of the shared core failure kinds, so one error
 * class can never grow two status codes across features. It takes the
 * classified info rather than the raw error: a feature with arms of its own
 * renders those and delegates the rest here, and doing that through the same
 * exhaustive switch is what makes a new shared kind a compile error everywhere
 * instead of a silent 500.
 */
export function coreErrorResponse(info: CoreErrorInfo): Response {
  switch (info.kind) {
    case "validation":
      return jsonError(info.message, CORE_ERROR_CODE.validation, 400);
    case "quota":
      return jsonRateLimited(info.usage);
    case "busy":
      return jsonError(
        "Service is busy, please try again shortly",
        CORE_ERROR_CODE.busy,
        503,
      );
  }
}
