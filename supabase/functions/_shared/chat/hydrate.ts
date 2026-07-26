/**
 * Default `AnswerHydrator`: fetch the referenced rows from Postgres.
 *
 * The model answers with ids, never with data — it can only name rows a search
 * tool actually returned — so the row a caller renders is read here rather than
 * taken from the model's output. What is read is the app's shape: a full
 * product detail, so a card can open its page without a second round trip.
 *
 * That shape is this implementation's choice, not the core's, which is why it is
 * a port: a platform whose card needs four fields substitutes a hydrator that
 * selects four columns, and how the rows become an answer is unaffected.
 */
import { SupabaseClient } from "jsr:@supabase/supabase-js@2";
import { PRODUCT_SELECT, WARDROBE_SELECT } from "./logic.ts";
import type { AnswerHydrator, AnswerRef, ContentBlock } from "./types.ts";

/**
 * Run the caller's prepared query with an `.in("id", ids)` filter and key the
 * result by row id. Empty ids → empty map (no query); an id whose row is gone
 * is simply absent, and the assembler drops its block.
 *
 * `toBlock` is how a hydrator says what a row is worth rendering as. It may
 * return null to drop a row the caller cannot render — the same outcome, by the
 * same missing-row rule, as a row that was deleted between search and answer.
 * Exported so a substituted hydrator inherits this contract rather than
 * restating it: which of these rules holds is what `assembleAnswerBlocks`
 * depends on, not incidental query code.
 */
export async function fetchRowsByIds(
  // deno-lint-ignore no-explicit-any
  query: any,
  ids: string[],
  // deno-lint-ignore no-explicit-any
  toBlock: (row: Record<string, any>) => ContentBlock | null = (row) => row,
): Promise<Map<string, ContentBlock>> {
  const map = new Map<string, ContentBlock>();
  if (ids.length === 0) return map;
  const { data, error } = await query.in("id", ids);
  if (error) throw error;
  for (const row of data ?? []) {
    const block = toBlock(row);
    if (block) map.set(String(row.id), block);
  }
  return map;
}

type ItemRef = Extract<AnswerRef, { id: string }>;

export const idsOf = (refs: AnswerRef[], type: ItemRef["type"]): string[] =>
  refs.filter((r): r is ItemRef => r.type === type).map((r) => r.id);

export const supabaseAnswerRows: AnswerHydrator = async (
  admin: SupabaseClient,
  userId: string,
  refs: AnswerRef[],
) => {
  const [products, wardrobe] = await Promise.all([
    fetchRowsByIds(
      admin.from("products").select(PRODUCT_SELECT),
      idsOf(refs, "product"),
    ),
    fetchRowsByIds(
      admin.from("wardrobe_items").select(WARDROBE_SELECT).eq("user_id", userId),
      idsOf(refs, "wardrobe"),
    ),
  ]);
  return { products, wardrobe };
};
