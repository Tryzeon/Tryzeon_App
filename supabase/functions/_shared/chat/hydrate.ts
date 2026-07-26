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
 * result. Empty ids → empty map (no query); an id whose row is gone is simply
 * absent, and the assembler drops its block.
 */
async function fetchRowsByIds(
  // deno-lint-ignore no-explicit-any
  query: any,
  ids: string[],
): Promise<Map<string, ContentBlock>> {
  const map = new Map<string, ContentBlock>();
  if (ids.length === 0) return map;
  const { data, error } = await query.in("id", ids);
  if (error) throw error;
  for (const row of data ?? []) map.set(String(row.id), row);
  return map;
}

type ItemRef = Extract<AnswerRef, { id: string }>;

const idsOf = (refs: AnswerRef[], type: ItemRef["type"]): string[] =>
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
