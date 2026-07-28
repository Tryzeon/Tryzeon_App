/**
 * The one Upstash Redis connection this project uses.
 *
 * Two callers now — the abuse rate limiter and LINE's conversation store — and
 * they share a client rather than each building their own: the credentials are
 * one pair of env vars, and a third use should not mean a third copy of this
 * literal drifting out of step with the others.
 */
import { Redis } from "npm:@upstash/redis";

export const redis = new Redis({
  url: Deno.env.get("UPSTASH_REDIS_REST_URL")!,
  token: Deno.env.get("UPSTASH_REDIS_REST_TOKEN")!,
});
