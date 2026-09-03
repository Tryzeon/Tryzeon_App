import { Ratelimit } from "npm:@upstash/ratelimit";
import { redis } from "./redis.ts";

const limiters = new Map<string, Ratelimit>();

function getLimiter(
  bucket: string,
  limit: number,
  windowSeconds: number,
): Ratelimit {
  const key = `${bucket}:${limit}:${windowSeconds}`;
  let limiter = limiters.get(key);
  if (!limiter) {
    limiter = new Ratelimit({
      redis: redis(),
      limiter: Ratelimit.slidingWindow(limit, `${windowSeconds} s`),
      prefix: bucket,
    });
    limiters.set(key, limiter);
  }
  return limiter;
}

/**
 * core functionality on a third-party outage. Rate limiting is abuse
 * prevention, not a billing quota, so occasional misses are acceptable.
 */
export async function checkRateLimit(
  userId: string,
  bucket: string,
  limit: number,
  windowSeconds: number,
): Promise<boolean> {
  try {
    const { success } = await getLimiter(bucket, limit, windowSeconds)
      .limit(userId);
    return success;
  } catch (error) {
    console.error("checkRateLimit error (failing open)", error);
    return true;
  }
}
