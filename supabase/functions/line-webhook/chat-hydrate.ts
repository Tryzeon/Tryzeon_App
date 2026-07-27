/**
 * This channel's `AnswerHydrator`: the handful of fields one card shows.
 *
 * The core's default hydrator reads a full product detail so an app card can
 * open its page without a second round trip. A LINE card has no page to open,
 * so it selects only the fields a card needs — see `product-card.ts` for the
 * columns (`PRODUCT_CARD_SELECT`) and the shape they land in (`LineProduct`).
 * This is the substitution the port exists for, not a variant of the app's
 * query.
 *
 * Only products are fetched. A LINE identity is always a freshly minted
 * `line_<sub>@liff.tryzeon.app` account — `getOrCreateUserId` is the sole writer
 * of `line_user_links` and it never binds an existing one — so its wardrobe is
 * empty by construction and no wardrobe id can name a real row. The map is
 * returned empty rather than omitted: should the model produce a wardrobe block
 * anyway, `assembleAnswerBlocks` drops it under the same missing-row rule it
 * applies to a since-deleted product.
 */
import type { AnswerHydrator, ContentBlock } from "../_shared/chat/index.ts";
import { fetchRowsByIds, idsOf } from "../_shared/chat/hydrate.ts";
import { PRODUCT_CARD_SELECT, toLineProduct } from "./product-card.ts";

export function makeLineAnswerRows(imagesBaseUrl: string): AnswerHydrator {
  return async (admin, _userId, refs) => ({
    products: await fetchRowsByIds(
      admin.from("products").select(PRODUCT_CARD_SELECT),
      idsOf(refs, "product"),
      (row) => toLineProduct(row, imagesBaseUrl),
    ),
    wardrobe: new Map<string, ContentBlock>(),
  });
}
