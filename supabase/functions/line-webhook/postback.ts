import { isUuid } from "../_shared/text.ts";

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
