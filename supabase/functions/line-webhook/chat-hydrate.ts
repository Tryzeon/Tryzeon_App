/**
 * The wardrobe read is bound to `userId`; the catalog is public, a wardrobe is
 * not.
 */
import type { AnswerHydrator } from "../_shared/chat/index.ts";
import { idsOf } from "../_shared/chat/hydrate.ts";
import { fetchProductRows } from "./product-card.ts";
import { fetchWardrobeRows } from "./wardrobe-card.ts";

export function makeLineAnswerRows(imagesBaseUrl: string): AnswerHydrator {
  return async (admin, userId, refs) => {
    const [products, wardrobe] = await Promise.all([
      fetchProductRows(admin, idsOf(refs, "product"), imagesBaseUrl),
      fetchWardrobeRows(admin, userId, idsOf(refs, "wardrobe")),
    ]);
    return { products, wardrobe };
  };
}
