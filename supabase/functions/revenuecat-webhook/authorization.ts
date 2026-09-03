import { timingSafeEqual } from "jsr:@std/crypto@^1.1.0/timing-safe-equal";

const BEARER_PREFIX = "Bearer ";

/**
 * RevenueCat sends the dashboard's "Authorization header value" verbatim, so the
 * header may or may not carry a scheme depending on how it was typed there.
 */
export function isAuthorized(header: string | null, secret: string): boolean {
  if (!header) return false;

  const token = header.startsWith(BEARER_PREFIX)
    ? header.slice(BEARER_PREFIX.length)
    : header;

  const encoder = new TextEncoder();
  const received = encoder.encode(token);
  const want = encoder.encode(secret);

  return received.byteLength === want.byteLength && timingSafeEqual(received, want);
}
