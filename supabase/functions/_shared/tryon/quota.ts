import { type FeatureName, supabaseUsageCounter } from "../quota.ts";
import type { QuotaFactory, TryonMode } from "./types.ts";
import type { DbClient } from "../supabase.ts";

/**
 * A total map rather than a ternary: a mode added later has to be priced here
 * or the module stops compiling, instead of being billed as a still image.
 */
const FEATURE_BY_MODE: Record<TryonMode, FeatureName> = {
  image: "tryon",
  video: "tryon_video",
};

export const supabaseQuota = (admin: DbClient): QuotaFactory =>
(userId, mode) => supabaseUsageCounter(admin, userId, FEATURE_BY_MODE[mode]);
