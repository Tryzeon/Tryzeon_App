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
 * Wardrobe comes back empty: this channel has no card for one yet, so the map
 * is returned rather than omitted and `assembleAnswerBlocks` drops any wardrobe
 * block under the same missing-row rule it applies to a since-deleted product.
 * It is no longer empty *by construction* — the app's LINE sign-in means a LINE
 * identity can own wardrobe items — so this drops answers the model meant.
 */
import type { AnswerHydrator, ContentBlock } from "../_shared/chat/index.ts";
import { idsOf } from "../_shared/chat/hydrate.ts";
import { fetchProductCards } from "./product-card.ts";

export function makeLineAnswerRows(imagesBaseUrl: string): AnswerHydrator {
  return async (admin, _userId, refs) => ({
    products: await fetchProductCards(admin, idsOf(refs, "product"), imagesBaseUrl),
    wardrobe: new Map<string, ContentBlock>(),
  });
}
