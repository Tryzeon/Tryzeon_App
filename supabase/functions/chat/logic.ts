// Pure helpers for the chat agent loop. No external imports so they unit-test
// offline (no Gemini SDK, no network).

// Columns a wardrobe item needs to render a card. Shared by the search tool and
// the by-id answer fetch so the two queries can't drift.
export const WARDROBE_SELECT = "id, image_path, category, tags, created_at, updated_at";

// Shop product shape for an answer card — mirrors the product detail page so the
// client renders it directly (sizes + the owning store's public fields).
export const PRODUCT_SELECT =
  "*, product_sizes(*), store_profiles!products_store_id_fkey(id, name, address, logo_path, channels)";

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

// Map the standard conversation to AI SDK `ModelMessage[]`. The whole history is
// replayed verbatim and uncompressed: assistant tool_use → a `tool-call` part,
// the paired user tool_result → a `tool` message with a `tool-result` part (its
// tool name resolved from the tool_use id), text passes through. Recommended
// product blocks collapse to a short id reference (their full data is already
// replayed in the tool_result, so nothing is lost to the model).
export function toModelMessages(messages: ChatMessage[]): any[] {
  // tool_use id → tool name, so a tool_result can name its tool.
  const nameOf = new Map<string, string>();
  for (const m of messages ?? []) {
    if (m?.role !== "assistant") continue;
    for (const b of Array.isArray(m.content) ? m.content : []) {
      if (b?.type === "tool_use" && b.id && b.name) nameOf.set(String(b.id), String(b.name));
    }
  }

  const out: any[] = [];
  for (const m of messages ?? []) {
    const blocks = Array.isArray(m?.content) ? m.content : [];

    if (m?.role === "user") {
      // tool_result blocks become a `tool` message; plain text stays a user turn.
      const toolResults = blocks.filter((b) => b?.type === "tool_result");
      if (toolResults.length) {
        out.push({
          role: "tool",
          content: toolResults.map((b) => ({
            type: "tool-result",
            toolCallId: String(b.tool_use_id),
            toolName: nameOf.get(String(b.tool_use_id)) ?? "unknown",
            output: { type: "json", value: b.content ?? {} },
          })),
        });
      }
      const text = blocks
        .filter((b) => b?.type === "text")
        .map((b) => nonEmptyStr(b.text))
        .filter((t): t is string => t !== null)
        .join("\n");
      if (text) out.push({ role: "user", content: text });
      continue;
    }

    // assistant
    const toolUses = blocks.filter((b) => b?.type === "tool_use" && b.name);
    const lines: string[] = [];
    for (const b of blocks) {
      const t = b?.type === "text" ? nonEmptyStr(b.text) : null;
      if (t) lines.push(t);
      else if (b?.type === "shop_product") lines.push(`（推薦商品 id:${b.id ?? b.item?.id ?? ""}）`);
      else if (b?.type === "wardrobe_product") lines.push(`（推薦衣櫃單品 id:${b.id ?? b.item?.id ?? ""}）`);
    }
    const text = lines.join("\n").trim();

    if (toolUses.length) {
      const content: any[] = [];
      if (text) content.push({ type: "text", text });
      for (const b of toolUses) {
        content.push({
          type: "tool-call",
          toolCallId: String(b.id),
          toolName: String(b.name),
          input: b.input ?? {},
        });
      }
      out.push({ role: "assistant", content });
    } else if (text) {
      out.push({ role: "assistant", content: text });
    }
  }
  return out;
}

// One ordered piece of the structured answer output: a line of text, or a
// reference to a shop product / wardrobe item by its real id (the model labels which).
export type AnswerRef =
  | { type: "text"; text: string }
  | { type: "product"; id: string }
  | { type: "wardrobe"; id: string };

// Parse the structured answer output into ordered refs. The model picks the block
// type (product = shop, wardrobe = wardrobe) and gives the id; the edge fetches each
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

// Assemble the ordered answer blocks from parsed refs + the rows fetched by id.
// Text passes through; product/wardrobe refs become card blocks, dropping any id
// whose row is missing (e.g. a since-deleted item).
export function assembleAnswerBlocks(
  refs: AnswerRef[],
  products: Map<string, Record<string, any>>,
  wardrobe: Map<string, Record<string, any>>,
): ContentBlock[] {
  const blocks: ContentBlock[] = [];
  for (const ref of refs) {
    if (ref.type === "text") {
      blocks.push({ type: "text", text: ref.text });
    } else if (ref.type === "product") {
      const item = products.get(ref.id);
      if (item) blocks.push({ type: "shop_product", item });
    } else {
      const item = wardrobe.get(ref.id);
      if (item) blocks.push({ type: "wardrobe_product", item });
    }
  }
  return blocks;
}
