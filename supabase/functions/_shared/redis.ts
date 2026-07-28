/**
 * The one Upstash Redis connection this project uses.
 *
 * Two callers now — the abuse rate limiter and LINE's conversation store — and
 * they share a client rather than each building their own: the credentials are
 * one pair of env vars, and a third use should not mean a third copy of this
 * literal drifting out of step with the others.
 *
 * Built on first use, not at import, and kept for the isolate — the pattern
 * `tryon/vertex.ts` uses for its own credentials. Both callers reach this
 * module from code paths that do not always touch Redis (chat turns with an
 * empty conversation, rate-limit checks that never run), and every test that
 * imports either transitively imports this one; constructing at import time
 * made every such test print Upstash's "config missing" warning regardless of
 * whether the test ever called `redis()`.
 */
import { Redis } from "npm:@upstash/redis@^1.38.0";

let client: Redis | null = null;

export const redis = (): Redis =>
  client ??= new Redis({
    url: Deno.env.get("UPSTASH_REDIS_REST_URL")!,
    token: Deno.env.get("UPSTASH_REDIS_REST_TOKEN")!,
  });
