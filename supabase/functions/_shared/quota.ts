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
