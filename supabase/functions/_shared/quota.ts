import { SupabaseClient } from "jsr:@supabase/supabase-js@2";

export type FeatureName = "chat" | "tryon" | "tryon_video";

/**
 * One user's counters for one day — every feature's, not the charging one's.
 * Any charge returns the whole set and clients sync a single usage cache from
 * it, so this travels to them verbatim: it is the shape this module publishes,
 * which is why it is no longer named after the table it happens to be stored in.
 */
export interface DailyUsage {
  user_id: string;
  usage_date: string;
  tryon_count: number;
  chat_count: number;
  video_count: number;
}

export interface IncrementResult {
  success: boolean;
  usage: DailyUsage | null;
  error?: any;
}

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
 * depending on its payload. It lives here rather than in either feature for the
 * same reason {@link QuotaExceededError} does: the contract is the counter's,
 * and try-on and chat charging through two structurally identical interfaces
 * could only ever differ by accident. {@link supabaseQuotaPort} satisfies it;
 * each feature still declares its own factory, because what identifies a
 * counter differs (try-on has a mode, chat does not).
 */
export interface QuotaPort {
  charge(): Promise<{ allowed: boolean; usage: DailyUsage | null }>;
  refund(): Promise<void>;
}

/**
 * Atomically increments the feature usage count and returns the post-mutation
 * row. The row is also returned when `success` is false (rate-limit case),
 * so callers can sync UI even on rejection.
 */
export async function incrementFeatureUsage(
  adminClient: SupabaseClient,
  userId: string,
  featureName: FeatureName
): Promise<IncrementResult> {
  const { data, error } = await adminClient.rpc(
    "increment_feature_usage",
    { p_user_id: userId, p_feature_name: featureName }
  );

  if (error) {
    return { success: false, usage: null, error };
  }

  // RPC returns: { allowed: boolean, usage: DailyUsage | null }
  const allowed = Boolean(data?.allowed);
  const usage = (data?.usage ?? null) as DailyUsage | null;
  return { success: allowed, usage };
}

/**
 * Decrements the feature usage count for a user (rollback operation).
 * Used to compensate for failed operations after quota was already incremented.
 */
export async function rollbackFeatureUsage(
  adminClient: SupabaseClient,
  userId: string,
  featureName: FeatureName
): Promise<{ success: boolean; error?: any }> {
  const { data: wasRolledBack, error } = await adminClient.rpc(
    "decrement_feature_usage",
    { p_user_id: userId, p_feature_name: featureName }
  );

  if (error) {
    return { success: false, error };
  }

  return { success: wasRolledBack };
}

/**
 * Quota manager class that tracks quota state and provides automatic rollback.
 *
 * Usage:
 * ```
 * const qm = new QuotaManager(adminClient, userId, featureName);
 * const { allowed, usage } = await qm.incrementQuota();
 * if (!allowed) return rateLimitResponse(usage);
 *
 * try {
 *   // ... do work that might fail
 * } catch (err) {
 *   await qm.rollbackQuota();
 *   throw err;
 * }
 * ```
 */
export class QuotaManager {
  private quotaIncremented = false;

  constructor(
    private adminClient: SupabaseClient,
    private userId: string,
    private featureName: FeatureName
  ) {}

  /**
   * Increments quota and returns both the allow/reject flag and the
   * post-mutation row (or current row when rejected).
   */
  async incrementQuota(): Promise<{ allowed: boolean; usage: DailyUsage | null }> {
    const { success, usage, error } = await incrementFeatureUsage(
      this.adminClient,
      this.userId,
      this.featureName
    );

    if (error) {
      throw new Error(`Failed to increment quota: ${error.message}`);
    }

    if (success) {
      this.quotaIncremented = true;
    }

    return { allowed: success, usage };
  }

  /**
   * Rolls back quota if it was previously incremented.
   * Safe to call multiple times — only rollbacks once.
   */
  async rollbackQuota(): Promise<void> {
    if (!this.quotaIncremented) return;

    const { success, error } = await rollbackFeatureUsage(
      this.adminClient,
      this.userId,
      this.featureName
    );

    if (error) {
      console.error("Quota rollback failed:", {
        userId: this.userId,
        featureName: this.featureName,
        error
      });
    }

    this.quotaIncremented = false;
  }

  get isQuotaIncremented(): boolean {
    return this.quotaIncremented;
  }
}

/**
 * The default {@link QuotaPort}: one user's counter for one feature, backed by
 * the `increment_feature_usage` / `decrement_feature_usage` RPC pair.
 *
 * This is the only place a core's charge/refund vocabulary meets those RPC
 * names, so no orchestrator depends on their payload shape and a test can
 * substitute the counter the way it substitutes any other port. It lives beside
 * the port it satisfies rather than in a feature, because the adaptation is the
 * counter's and not any one caller's — a feature contributes only which counter
 * to charge, which is why each still declares its own factory (try-on derives
 * the feature from a mode, chat has exactly one).
 */
export function supabaseQuotaPort(
  adminClient: SupabaseClient,
  userId: string,
  featureName: FeatureName,
): QuotaPort {
  const manager = new QuotaManager(adminClient, userId, featureName);
  return {
    charge: () => manager.incrementQuota(),
    refund: () => manager.rollbackQuota(),
  };
}
