// Pure helpers for the chat agent loop. No external imports so they unit-test
// offline (no Gemini SDK, no network).

const nonEmptyArray = (v: unknown): unknown[] | null =>
  Array.isArray(v) && v.length > 0 ? v : null;

// Trimmed string, or null when missing/blank.
export const nonEmptyStr = (v: unknown): string | null =>
  typeof v === "string" && v.trim() !== "" ? v.trim() : null;

// Assemble list_shop_products RPC params from model tool args + resolved context.
// gender is an optional model-chosen filter (args.gender), not a forced one —
// the model decides whether to apply it, informed by the user context in the prompt.
export function mapSearchProductsArgs(
  args: Record<string, unknown>,
  opts: { categoryIds: string[] | null; limit?: number },
) {
  return {
    p_store_id: null,
    p_search_query: nonEmptyStr(args.query),
    p_category_ids: opts.categoryIds && opts.categoryIds.length > 0 ? opts.categoryIds : null,
    p_min_price: typeof args.min_price === "number" ? args.min_price : null,
    p_max_price: typeof args.max_price === "number" ? args.max_price : null,
    p_channels: nonEmptyArray(args.channels),
    p_gender: nonEmptyStr(args.gender),
    p_materials: nonEmptyArray(args.materials),
    p_elasticities: nonEmptyArray(args.elasticities),
    p_fits: nonEmptyArray(args.fits),
    p_thicknesses: nonEmptyArray(args.thicknesses),
    p_styles: nonEmptyArray(args.styles),
    p_seasons: nonEmptyArray(args.seasons),
    p_sort_column: "created_at",
    p_sort_ascending: false,
    p_limit: opts.limit ?? 10,
    p_offset: 0,
  };
}

// The conversation schema, shared by client storage, the wire (both directions),
// and rendering. Standard chat-API shape: only user/assistant roles, each a list
// of content blocks. A tool round spans messages — a `tool_use` block in an
// assistant message paired (by id) with a `tool_result` block in a user message.
export type ContentBlock = Record<string, any>;
export type ChatMessage = { role: string; content: ContentBlock[] };

// Map the standard conversation to Gemini `contents`. The whole history is
// replayed verbatim and uncompressed: assistant tool_use → functionCall, full
// user tool_result → functionResponse (its tool name resolved from the paired
// tool_use id), text passes through. Recommended product blocks collapse to a
// short id reference (their full data is already replayed in the tool_result, so
// nothing is lost).
export function toContents(messages: ChatMessage[]): any[] {
  // tool_use id → tool name, so a tool_result can name its function for Gemini.
  const nameOf = new Map<string, string>();
  for (const m of messages ?? []) {
    if (m?.role !== "assistant") continue;
    for (const b of Array.isArray(m.content) ? m.content : []) {
      if (b?.type === "tool_use" && b.id && b.name) nameOf.set(String(b.id), String(b.name));
    }
  }

  const contents: any[] = [];
  for (const m of messages ?? []) {
    const blocks = Array.isArray(m?.content) ? m.content : [];
    const parts: any[] = [];
    if (m?.role === "user") {
      for (const b of blocks) {
        if (b?.type === "text" && nonEmptyStr(b.text)) parts.push({ text: b.text });
        else if (b?.type === "tool_result") {
          const name = nameOf.get(String(b.tool_use_id)) ?? "tool";
          parts.push({ functionResponse: { name, response: b.content ?? {} } });
        }
      }
      if (parts.length) contents.push({ role: "user", parts });
    } else if (m?.role === "assistant") {
      for (const b of blocks) {
        if (b?.type === "text" && nonEmptyStr(b.text)) {
          parts.push({ text: b.text });
        } else if (b?.type === "tool_use" && b.name) {
          parts.push({ functionCall: { name: b.name, args: b.input ?? {} } });
        } else if (b?.type === "shop_product") {
          parts.push({ text: `（推薦商品 id:${b.id ?? b.item?.id ?? ""}）` });
        } else if (b?.type === "wardrobe_product") {
          parts.push({ text: `（推薦衣櫃單品 id:${b.id ?? b.item?.id ?? ""}）` });
        }
      }
      if (parts.length) contents.push({ role: "model", parts });
    }
  }
  return contents;
}

// One ordered piece of a respond() call: a line of text, or a reference to a
// shop product / wardrobe item by its real id (the model labels which).
export type AnswerRef =
  | { type: "text"; text: string }
  | { type: "product"; id: string }
  | { type: "wardrobe"; id: string };

// Parse a respond() tool call into ordered refs. The model picks the block type
// (product = shop, wardrobe = wardrobe) and gives the id; the edge fetches each
// id from the matching table. Empty text and id-less product/wardrobe blocks drop.
export function parseAnswerRefs(args: Record<string, any>): AnswerRef[] {
  const rawBlocks = Array.isArray(args?.blocks) ? args.blocks : [];
  const refs: AnswerRef[] = [];
  for (const b of rawBlocks) {
    if (b?.type === "product" || b?.type === "wardrobe") {
      const id = nonEmptyStr(b.id);
      if (id) refs.push({ type: b.type, id });
    } else if (b?.type === "text") {
      const text = nonEmptyStr(b.text);
      if (text) refs.push({ type: "text", text });
    }
  }
  return refs;
}
