/**
 * Test doubles for the usage counter, shared by every feature's quota tests.
 *
 * Not a `*.test.ts` file, so the runner does not collect it, and nothing in
 * production imports it. It lives here rather than in one feature because the
 * counter is shared: a `DailyUsage` field added later should be one edit, not
 * one per core that ever faked a charge.
 */
import type { DailyUsage } from "./quota.ts";
import type { DbClient } from "./supabase.ts";

/** A usage row with every counter present, for assertions that echo it back. */
export const SAMPLE_USAGE: DailyUsage = {
  user_id: "u1",
  usage_date: "2026-07-26",
  tryon_count: 0,
  chat_count: 0,
  video_count: 0,
};

export interface RpcCall {
  fn: string;
  args: Record<string, unknown>;
}

/**
 * An admin client that records every RPC a quota port issues, and answers
 * `increment_feature_usage` with the scripted allow/reject.
 */
export function fakeQuotaAdmin(allowed = true): {
  client: DbClient;
  calls: RpcCall[];
} {
  const calls: RpcCall[] = [];
  const client = {
    rpc(fn: string, args: Record<string, unknown>) {
      calls.push({ fn, args });
      if (fn === "increment_feature_usage") {
        return Promise.resolve({
          data: { allowed, usage: SAMPLE_USAGE },
          error: null,
        });
      }
      return Promise.resolve({ data: true, error: null });
    },
  } as unknown as DbClient;
  return { client, calls };
}
