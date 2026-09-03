import type { DailyUsage, UsageCounter } from "../quota.ts";
import type { DbClient } from "../supabase.ts";

export type { UsageCounter };

/**
 * The conversation schema, shared by client storage, the wire (both
 * directions), and rendering. Standard chat-API shape: only user/assistant
 * roles, each a list of content blocks. A tool round spans messages — a
 * `tool_use` block in an assistant message paired (by id) with a `tool_result`
 * block in a user message.
 */
export type ContentBlock = Record<string, any>;
export type ChatMessage = { role: ChatRole; content: ContentBlock[] };

export type ChatRole = "user" | "assistant";

/**
 * One ordered piece of the model's structured answer: a line of text, or a
 * reference to a shop product / wardrobe item by its real id (the model labels
 * which). Refs are what the core hydrates; blocks are what it returns.
 */
export type AnswerRef =
  | { type: "text"; text: string }
  | { type: "product"; id: string }
  | { type: "wardrobe"; id: string };

/**
 * A progress event emitted while the agent loop runs, so a caller can surface
 * live "searching…" feedback. Transport-agnostic: the chat edge wraps each in
 * NDJSON, a LINE adapter may ignore them or map them to a loading indicator.
 * Terminal outcomes are NOT events — the run returns {@link ChatResult} or
 * throws; the caller shapes its own done/error frame from `classifyCoreError`.
 */
export type ChatEvent =
  | { type: "tool_use"; id: string; name: string; input: unknown }
  | { type: "tool_result"; tool_use_id: string; content: unknown };

export interface ChatParams {
  userId: string;
  /** Full prior conversation in the shared wire shape (user/assistant blocks). */
  messages: ChatMessage[];
  /** Optional progress sink for tool_use/tool_result events during the loop. */
  onEvent?: (ev: ChatEvent) => void;
}

export interface ChatResult {
  /** Ordered answer blocks (text / product / wardrobe) to render. */
  blocks: ContentBlock[];
  /**
   * Every turn this run added to the conversation, in order: one message per
   * tool call, one per tool result, then the assistant's answer.
   *
   * Without this, a caller continuing the conversation would have to rebuild
   * the tool rounds from {@link ChatEvent}s and re-derive which role each block
   * belongs to — a rule the model's transcript depends on, reimplemented per
   * platform. Append these and the next turn's history is correct by
   * construction.
   */
  messages: ChatMessage[];
  /** Post-charge quota row, echoed so callers can sync usage UI. */
  usage: DailyUsage | null;
}

/**
 * What a caller may send, enforced by `validateChatParams` and by nothing else.
 *
 * A port's own budget — how many tool calls its loop takes, how many rows its
 * search returns — is private to whichever implementation is wired in, so
 * publishing it would tell an adapter it is bound by a number its substituted
 * runner is free to ignore.
 */
export const LIMITS = {
  /**
   * Cap on replayed history: `toModelMessages` replays every turn verbatim, so
   * an unbounded conversation is an unbounded per-request cost. Generous enough
   * that no real session in the app reaches it — it exists so a server-side
   * conversation store, which has no client deciding when to forget, cannot
   * grow without one.
   */
  MAX_MESSAGES: 400,
  /** Cap on one text block, applied to both directions of the transcript. */
  MAX_TEXT_LENGTH: 2000,
} as const;

/*
 * Ports the core depends on. `run.ts` is written against these signatures and
 * wires the Supabase / Vertex implementations as its defaults, so swapping one
 * (or a test double) is a substitution rather than an edit to the orchestrator.
 */

/**
 * Opens the quota counter for one user. Takes no client, for the reason
 * `_shared/tryon/types.ts` sets out under its own `QuotaFactory`: the quota RPCs
 * are granted to `service_role` alone, so the adapter binds that credential in
 * (see `supabaseChatQuota`) and the core is handed a capability instead.
 */
export type ChatQuotaFactory = (userId: string) => UsageCounter;

/** The per-request grounding a turn runs against. */
export interface ChatContext {
  /** The fully-assembled system prompt (persona + user context + categories). */
  systemInstruction: string;
  /** Category name → its id, for resolving the model's category_name filter. */
  categoryIdByName: Map<string, string>;
}

export type ContextLoader = (
  client: DbClient,
  userId: string,
) => Promise<ChatContext>;

/**
 * What the agent loop needs to run one turn. The grounding arrives whole rather
 * than spread into its parts: the prompt promises the model a vocabulary and
 * the map is what makes that promise resolvable, so passing them separately
 * would only give them room to disagree.
 */
export interface AgentRequest {
  client: DbClient;
  userId: string;
  context: ChatContext;
  messages: ChatMessage[];
  onEvent?: (ev: ChatEvent) => void;
}

export interface AgentAnswer {
  /**
   * The model's structured answer, or null when it produced none usable. Null
   * rather than a throw because a model that ran and said nothing coherent is
   * an outcome the core degrades gracefully, not a fault — and telling the two
   * apart is the implementation's job, since only it knows what its SDK raises.
   */
  output: Record<string, any> | null;
  /** The tool rounds the loop took, already in conversation shape. */
  rounds: ChatMessage[];
}

/**
 * Runs the tool-using agent loop for one turn. Takes what the tools need rather
 * than the tools themselves, so the SDK's tool vocabulary stays on the
 * implementation side of the port.
 */
export type AgentRunner = (req: AgentRequest) => Promise<AgentAnswer>;

/** Rows referenced by an answer, keyed by id, per kind. */
export interface AnswerRows {
  products: Map<string, ContentBlock>;
  wardrobe: Map<string, ContentBlock>;
}

/**
 * Fetches the rows an answer referenced. Returns rows rather than finished
 * blocks so that assembly stays in `assembleAnswerBlocks`, while what a row
 * *contains* — the app wants a full product detail, another platform may want
 * four fields — stays the implementation's choice.
 */
export type AnswerHydrator = (
  client: DbClient,
  userId: string,
  refs: AnswerRef[],
) => Promise<AnswerRows>;
