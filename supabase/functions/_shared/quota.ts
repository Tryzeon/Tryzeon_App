import type { Tables } from "./database.types.ts";
import { asJsonObject, type DbClient } from "./supabase.ts";

export type FeatureName = "chat" | "tryon" | "tryon_video";

/**
 * One user's counters for one day — every feature's, not the charging one's.
 * Any charge returns the whole set and clients sync a single usage cache from
 * it, so this travels to them verbatim. It is still `user_daily_usage`'s row,
 * so the columns come from the generated schema rather than being restated here.
 */
export type DailyUsage = Tables<"user_daily_usage">;

/**
 * Thrown when a charge is rejected because the caller's daily quota is spent.
 * Carries the current usage row so the caller can report the limit it hit.
 *
 * Lives here rather than in each feature because the condition is this
 * module's: every feature charges through the same counter and fails the same
 * way, so two classes could only ever differ by accident.
 */
export class QuotaExceededError extends Error {
  constructor(public readonly usage: DailyUsage | null) {
    super("quota exceeded");
  }
}

/**
 * The usage counter one unit of work is charged against. `charge` runs before
 * any work; `refund` compensates when that work then fails, and is a no-op if
 * the charge never landed.
 *
 * A port so a feature core can say what it needs — an atomic charge with a
 * compensating refund — without naming the RPC pair that implements it or
 * depending on its payload.
 *
 * It lives here rather than in either feature for the same reason
 * {@link QuotaExceededError} does: the contract is the counter's, and try-on
 * and chat charging through two structurally identical interfaces could only
 * ever differ by accident. {@link supabaseUsageCounter} satisfies it; each
 * feature still declares its own factory, because what identifies a counter
 * differs (try-on has a mode, chat does not).
 */
export interface UsageCounter {
  charge(): Promise<{ allowed: boolean; usage: DailyUsage | null }>;
  refund(): Promise<void>;
}

/**
 * The default {@link UsageCounter}: one user's counter for one feature, backed
 * by the `increment_feature_usage` / `decrement_feature_usage` RPC pair.
 *
 * This is the only place a core's charge/refund vocabulary meets those RPC
 * names, so no orchestrator depends on their payload shape and a test can
 * substitute the counter the way it substitutes any other port. It lives beside
 * the port it satisfies rather than in a feature, because the adaptation is the
 * counter's and not any one caller's — a feature contributes only which counter
 * to charge, which is why each still declares its own factory (try-on derives
 * the feature from a mode, chat has exactly one).
 *
 * "Did the charge land?" is a closure variable rather than a field on an object
 * a caller could reach: nothing outside `refund` may read or set it, and making
 * that structural is what keeps a double refund impossible rather than merely
 * discouraged.
 */
export function supabaseUsageCounter(
  adminClient: DbClient,
  userId: string,
  featureName: FeatureName,
): UsageCounter {
  let charged = false;
  const args = { p_user_id: userId, p_feature_name: featureName };

  return {
    async charge() {
      const { data, error } = await adminClient.rpc(
        "increment_feature_usage",
        args,
      );
      if (error) {
        throw new Error(`Failed to increment quota: ${error.message}`);
      }
      const result = asJsonObject<{ allowed: boolean; usage: DailyUsage | null }>(data);
      charged = Boolean(result?.allowed);
      return { allowed: charged, usage: result?.usage ?? null };
    },

    async refund() {
      if (!charged) return;
      // Cleared before the call, not after: a refund that throws must not leave
      // the port willing to issue a second one.
      charged = false;
      const { error } = await adminClient.rpc("decrement_feature_usage", args);
      if (error) {
        console.error("Quota rollback failed:", { userId, featureName, error });
      }
    },
  };
}
