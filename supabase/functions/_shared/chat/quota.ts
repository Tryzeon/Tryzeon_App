/**
 * Chat's `ChatQuotaFactory`: open the shared Supabase counter for the `chat`
 * feature.
 *
 * The feature name is a constant, not a parameter: chat charges one counter,
 * and try-on's `FEATURE_BY_MODE` map exists only because it charges two.
 */
import { SupabaseClient } from "jsr:@supabase/supabase-js@2";
import { supabaseUsageCounter } from "../quota.ts";
import type { ChatQuotaFactory } from "./types.ts";

/** An adapter binds its service-role client here; the core never sees it. */
export const supabaseChatQuota = (admin: SupabaseClient): ChatQuotaFactory =>
(userId) => supabaseUsageCounter(admin, userId, "chat");
