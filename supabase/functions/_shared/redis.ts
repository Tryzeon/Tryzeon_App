/**
 * Built on first use, not at import, and kept for the isolate — the pattern
 * `tryon/vertex.ts` uses for its own credentials. Both callers reach this
 * module from code paths that do not always touch Redis (chat turns with an
 * empty conversation, rate-limit checks that never run), and every test that
 * imports either transitively imports this one; constructing at import time
 * made every such test print Upstash's "config missing" warning regardless of
 * whether the test ever called `redis()`.
 */
import { Redis } from "@upstash/redis";

let client: Redis | null = null;

export const redis = (): Redis =>
  client ??= new Redis({
    url: Deno.env.get("UPSTASH_REDIS_REST_URL")!,
    token: Deno.env.get("UPSTASH_REDIS_REST_TOKEN")!,
  });
