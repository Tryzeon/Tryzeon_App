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
 */
import { isUuid } from "../_shared/text.ts";

const TRYON = "tryon";

export function tryonPostbackData(productId: string): string {
  return new URLSearchParams({ a: TRYON, pid: productId }).toString();
}

export type Postback = { kind: "tryon"; productId: string };

export function parsePostback(data: unknown): Postback | null {
  if (typeof data !== "string") return null;

  const params = new URLSearchParams(data);
  if (params.get("a") !== TRYON) return null;

  const productId = params.get("pid");
  return productId && isUuid(productId) ? { kind: TRYON, productId } : null;
}
