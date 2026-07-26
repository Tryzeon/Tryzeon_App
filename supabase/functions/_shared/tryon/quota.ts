/**
 * Default `QuotaPort`: the Supabase daily-usage RPC pair.
 *
 * This module is the only place the core's charge/refund vocabulary meets
 * `increment_feature_usage` / `decrement_feature_usage`, so the orchestrator no
 * longer depends on that RPC's payload shape and a test can substitute the
 * counter the same way it substitutes the generator or the uploader.
 */
import { type FeatureName, QuotaManager } from "../quota.ts";
import type { QuotaFactory, TryonMode } from "./types.ts";

/**
 * The counter each mode is charged against. A total map rather than a ternary:
 * a mode added later has to be priced here or the module stops compiling,
 * whereas `mode === "video" ? … : …` would quietly bill it as a still image.
 */
const FEATURE_BY_MODE: Record<TryonMode, FeatureName> = {
  image: "tryon",
  video: "tryon_video",
};

export const supabaseQuota: QuotaFactory = (admin, userId, mode) => {
  const manager = new QuotaManager(admin, userId, FEATURE_BY_MODE[mode]);
  return {
    charge: () => manager.incrementQuota(),
    refund: () => manager.rollbackQuota(),
  };
};
