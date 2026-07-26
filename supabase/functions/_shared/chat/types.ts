import { SupabaseClient } from "jsr:@supabase/supabase-js@2";
import { DailyUsage } from "../quota.ts";
import type { ChatMessage, ContentBlock } from "./logic.ts";

/**
 * A progress event emitted while the agent loop runs, so a caller can surface
 * live "searching…" feedback. Transport-agnostic: the chat edge wraps each in
 * NDJSON, a LINE adapter may ignore them or map them to a loading indicator.
 * Terminal outcomes are NOT events — the run returns {@link ChatResult} or
 * throws {@link QuotaExceededError}; the caller shapes its own done/error frame.
 */
export type ChatEvent =
  | { type: "tool_use"; id: string; name: string; input: unknown }
  | { type: "tool_result"; tool_use_id: string; content: unknown };

export interface RunChatAgentDeps {
  /** Privileged client for quota RPC, context queries, tool searches, id fetches. */
  admin: SupabaseClient;
}

export interface RunChatAgentParams {
  userId: string;
  /** Full prior conversation in the shared wire shape (user/assistant blocks). */
  messages: ChatMessage[];
  /** Optional progress sink for tool_use/tool_result events during the loop. */
  onEvent?: (ev: ChatEvent) => void;
}

export interface ChatResult {
  /** Ordered answer blocks (text / product / wardrobe) to render. */
  blocks: ContentBlock[];
  /** Post-increment quota row, echoed so callers can sync usage UI. */
  usage: DailyUsage | null;
}

