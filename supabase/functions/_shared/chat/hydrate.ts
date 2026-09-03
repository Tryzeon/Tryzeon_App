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
import { PRODUCT_SELECT, WARDROBE_SELECT } from "./logic.ts";
import type { AnswerHydrator, AnswerRef } from "./types.ts";
import type { DbClient } from "../supabase.ts";

/**
 * The one thing this needs of a PostgREST query builder: `.in("id", …)`, then
 * awaited. Structural rather than the real builder type so callers keep the row
 * shape their `.select()` inferred without this signature naming the five
 * schema type parameters that would otherwise erase it.
 */
interface IdInFilter<Row> {
  in(column: "id", values: string[]): PromiseLike<{ data: Row[] | null; error: unknown }>;
}

/**
 * Run the caller's prepared query with an `.in("id", ids)` filter and key the
 * result by row id. Empty ids → empty map (no query); an id whose row is gone
 * is simply absent, and the assembler drops its block.
 *
 * `toBlock` is how a hydrator says what a row is worth rendering as, and may
 * return null to drop one the caller cannot render — the same outcome, by the
 * same missing-row rule, as a row deleted between search and answer. Exported so
 * a substituted hydrator inherits these rules rather than restating them: they
 * are what `assembleAnswerBlocks` depends on, not incidental query code.
 */
export async function fetchRowsByIds<Row extends { id: string }, Block = Row>(
  query: IdInFilter<Row>,
  ids: string[],
  // The identity default is why `Block` defaults to `Row`; the two are only
  // unrelated to the compiler inside this body, hence the one assertion.
  toBlock: (row: Row) => Block | null = (row) => row as unknown as Block,
): Promise<Map<string, Block>> {
  const map = new Map<string, Block>();
  if (ids.length === 0) return map;
  const { data, error } = await query.in("id", ids);
  if (error) throw error;
  for (const row of data ?? []) {
    const block = toBlock(row);
    if (block) map.set(row.id, block);
  }
  return map;
}

type ItemRef = Extract<AnswerRef, { id: string }>;

export const idsOf = (refs: AnswerRef[], type: ItemRef["type"]): string[] =>
  refs.filter((r): r is ItemRef => r.type === type).map((r) => r.id);

export const supabaseAnswerRows: AnswerHydrator = async (
  client: DbClient,
  userId: string,
  refs: AnswerRef[],
) => {
  const [products, wardrobe] = await Promise.all([
    fetchRowsByIds(
      client.from("products").select(PRODUCT_SELECT),
      idsOf(refs, "product"),
    ),
    fetchRowsByIds(
      client.from("wardrobe_items").select(WARDROBE_SELECT).eq("user_id", userId),
      idsOf(refs, "wardrobe"),
    ),
  ]);
  return { products, wardrobe };
};
