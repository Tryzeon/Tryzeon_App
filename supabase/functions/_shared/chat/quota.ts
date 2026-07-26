/**
 * Chat's `ChatQuotaFactory`: open the shared Supabase counter for the `chat`
 * feature.
 *
 * The feature name is a constant, not a parameter: chat charges one counter,
 * and try-on's `FEATURE_BY_MODE` map exists only because it charges two.
 */
import { supabaseUsageCounter } from "../quota.ts";
import type { ChatQuotaFactory } from "./types.ts";

export const supabaseChatQuota: ChatQuotaFactory = (admin, userId) =>
  supabaseUsageCounter(admin, userId, "chat");
