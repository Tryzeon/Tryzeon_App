/**
 * This channel's `AnswerHydrator`: the handful of fields one card shows.
 *
 * The core's default hydrator reads a full product detail so an app card can
 * open its page without a second round trip. A LINE card has no page to open,
 * so it selects only the fields a card needs — see `product-card.ts` and
 * `wardrobe-card.ts` for the columns and the shapes they land in. This is the
 * substitution the port exists for, not a variant of the app's query.
 *
 * The two reads differ in one way that matters: the wardrobe one is bound to
 * `userId`, because the catalog is public and a wardrobe is not.
 */
import type { AnswerHydrator } from "../_shared/chat/index.ts";
import { idsOf } from "../_shared/chat/hydrate.ts";
import { fetchProductCards } from "./product-card.ts";
import { fetchWardrobeCards } from "./wardrobe-card.ts";

export function makeLineAnswerRows(imagesBaseUrl: string): AnswerHydrator {
  return async (admin, userId, refs) => {
    const [products, wardrobe] = await Promise.all([
      fetchProductCards(admin, idsOf(refs, "product"), imagesBaseUrl),
      fetchWardrobeCards(admin, userId, idsOf(refs, "wardrobe")),
    ]);
    return { products, wardrobe };
  };
}
