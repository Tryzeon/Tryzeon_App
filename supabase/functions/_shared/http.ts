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

/** Standard 429 rate-limit response. Pass `usage` to include quota details. */
export function rateLimitedResponse(usage?: unknown): Response {
  return json(
    usage === undefined
      ? { error: "Rate limit exceeded", code: "RATE_LIMIT_EXCEEDED" }
      : { error: "Rate limit exceeded", code: "RATE_LIMIT_EXCEEDED", usage },
    429,
  );
}
