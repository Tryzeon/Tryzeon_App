/**
 * The postback wire format, written and read in one place.
 *
 * A postback carries whatever string the card put in it, and the card is sent
 * from one module while the tap arrives in another — so encoding and parsing
 * live together, and no call site spells the format by hand.
 *
 * Parsing is total: every shape that is not a postback we issued comes back as
 * `null`, including one from a card sent by an older deploy. `isUuid` belongs
 * here rather than at the query because turning an untrusted string into a
 * value we are willing to act on is exactly what this layer is for.
 *
 * The action names were renamed to `tryon_product` / `tryon_wardrobe`, so a
 * card already sent under the old `tryon` name is one more shape parsing
 * rejects — back-compat for it was declined on purpose, not missed.
 */
import { isUuid } from "../_shared/text.ts";

/** The two actions a card can carry, each naming its noun, not a bare verb. */
const TRYON_PRODUCT = "tryon_product";
const TRYON_WARDROBE = "tryon_wardrobe";

export function productTryonPostbackData(productId: string): string {
  return new URLSearchParams({ a: TRYON_PRODUCT, pid: productId }).toString();
}

export function wardrobeTryonPostbackData(wardrobeItemId: string): string {
  return new URLSearchParams({ a: TRYON_WARDROBE, wid: wardrobeItemId }).toString();
}

export type Postback =
  | { kind: "product"; productId: string }
  | { kind: "wardrobe"; wardrobeItemId: string };

export function parsePostback(data: unknown): Postback | null {
  if (typeof data !== "string") return null;

  const params = new URLSearchParams(data);
  const action = params.get("a");

  if (action === TRYON_PRODUCT) {
    const productId = params.get("pid");
    return productId && isUuid(productId) ? { kind: "product", productId } : null;
  }
  if (action === TRYON_WARDROBE) {
    const wardrobeItemId = params.get("wid");
    return wardrobeItemId && isUuid(wardrobeItemId)
      ? { kind: "wardrobe", wardrobeItemId }
      : null;
  }
  return null;
}
