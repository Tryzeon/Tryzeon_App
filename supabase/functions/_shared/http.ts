// Shared JSON HTTP response helpers for Edge Functions.

const JSON_HEADERS = { "Content-Type": "application/json" } as const;

/** JSON response with an arbitrary body and status (default 200). */
export function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), { status, headers: JSON_HEADERS });
}

/** JSON error response with the standard `{ error, code }` body. */
export function jsonError(message: string, code: string, status: number): Response {
  return json({ error: message, code }, status);
}

/**
 * The standard 429 rate-limit response — a `jsonError` with its message, code
 * and status fixed, so every rate-limited endpoint answers identically. Pass
 * `usage` to include quota details.
 */
export function jsonRateLimited(usage?: unknown): Response {
  return json(
    usage === undefined
      ? { error: "Rate limit exceeded", code: "RATE_LIMIT_EXCEEDED" }
      : { error: "Rate limit exceeded", code: "RATE_LIMIT_EXCEEDED", usage },
    429,
  );
}
