/**
 * Try-on's `QuotaFactory`: pick the counter this mode is charged against, and
 * open it through the shared Supabase port.
 *
 * The RPC pair behind that port belongs to `_shared/quota.ts`; what is try-on's
 * is only the mapping below, which is the whole reason the factory is a
 * per-feature module at all.
 */
import { type FeatureName, supabaseUsageCounter } from "../quota.ts";
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

export const supabaseQuota: QuotaFactory = (admin, userId, mode) =>
  supabaseUsageCounter(admin, userId, FEATURE_BY_MODE[mode]);
