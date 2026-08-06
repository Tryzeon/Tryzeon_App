/**
 * What one product card is made of.
 *
 * Two surfaces render a product now — the chat answer's carousel and the
 * try-on result card — so "which fields a card shows" stopped being the
 * hydrator's business and became its own. `fetchProductCards` reads these
 * columns in batch for an answer; `fetchLineProduct` reads a single one for a
 * card the user pointed at by id.
 */
import { SupabaseClient } from "jsr:@supabase/supabase-js@2";
import { fetchRowsByIds } from "../_shared/chat/hydrate.ts";
import type { ContentBlock } from "../_shared/chat/index.ts";
import { publicImageUrl } from "../_shared/storage.ts";
import { CARD_COLOR } from "./card-kit.ts";

export const PRODUCT_CARD_SELECT =
  "id, name, price, image_paths, purchase_link, store_profiles!products_store_id_fkey(name)";

/** A shop product reduced to what one card displays. */
export interface LineProduct {
  id: string;
  name: string;
  price: number;
  /** Public R2 URL of the product's first image. */
  imageUrl: string;
  storeName: string | null;
  /** Destination for the card's purchase button, when the product has one. */
  purchaseUrl: string | null;
}

/**
 * One product row as a card's worth of fields, or null when it has no image.
 *
 * A card whose image is missing is a shopping card you cannot see, so an
 * image-less product is dropped. That same absence is what makes the product
 * un-try-on-able — `resolveProductGarment` rejects it for having no garment
 * material — so one check answers both questions.
 */
export function toLineProduct(
  // deno-lint-ignore no-explicit-any
  row: Record<string, any>,
  imagesBaseUrl: string,
): LineProduct | null {
  const key = (row.image_paths as string[] | null)?.[0];
  if (!key) return null;

  const store = row.store_profiles as { name?: string } | null;
  return {
    id: String(row.id),
    name: String(row.name),
    price: Number(row.price),
    imageUrl: publicImageUrl(imagesBaseUrl, key),
    storeName: store?.name ?? null,
    purchaseUrl: row.purchase_link ?? null,
  };
}

/**
 * The referenced products as cards, keyed by id. An id whose row is gone — or
 * whose product has no image — is simply absent, and the assembler drops its
 * block.
 */
export function fetchProductCards(
  admin: SupabaseClient,
  ids: string[],
  imagesBaseUrl: string,
): Promise<Map<string, ContentBlock>> {
  return fetchRowsByIds(
    admin.from("products").select(PRODUCT_CARD_SELECT),
    ids,
    (row) => toLineProduct(row, imagesBaseUrl),
  );
}

/**
 * One product as a card, or null when there is nothing renderable to show —
 * the row is gone, or it has no image. A failed lookup throws instead: a
 * missing product is something the user can be told about, a broken query is
 * ours to fix.
 */
export async function fetchLineProduct(
  admin: SupabaseClient,
  productId: string,
  imagesBaseUrl: string,
): Promise<LineProduct | null> {
  const { data, error } = await admin
    .from("products")
    .select(PRODUCT_CARD_SELECT)
    .eq("id", productId)
    .maybeSingle();

  if (error) throw new Error(`product lookup failed: ${error.message}`);
  return data ? toLineProduct(data, imagesBaseUrl) : null;
}

/**
 * The card's purchase action, or null.
 *
 * A LINE uri action only accepts an absolute http(s) link, and one it rejects
 * fails the whole send rather than the one button — so a link that cannot be
 * an action simply isn't offered as one, and the card falls back to being
 * display-only.
 *
 * "Absolute http(s)" is checked with the `URL` parser, not a prefix test:
 * `startsWith("http")` also accepts `"httpfoo://x"` and, because `URL`
 * normalizes a single-slash scheme into a double-slash one, a bare protocol
 * check on the *parsed* result would still wave through `"https:/one-slash"`
 * even though that literal string is not something LINE accepts — so the
 * scheme is also confirmed against the original, unnormalized input.
 */
export function purchaseAction(product: LineProduct): object | null {
  const url = product.purchaseUrl;
  if (!url) return null;

  let parsed: URL;
  try {
    parsed = new URL(url);
  } catch {
    return null;
  }

  const isHttpOrHttps = parsed.protocol === "http:" || parsed.protocol === "https:";
  const hasDoubleSlash = url.toLowerCase().startsWith(`${parsed.protocol}//`);
  return isHttpOrHttps && hasDoubleSlash
    ? { type: "uri", label: "前往購買", uri: url }
    : null;
}

/** A price with thousands separators and no cents: `1,280`. */
export function amountText(price: number): string {
  return Math.round(price).toLocaleString("en-US");
}

/**
 * The name / price / store lines both cards show.
 *
 * The price is one text carrying two spans rather than one string, because
 * this is the only hierarchy Flex can express: `docs/ui-design-system.md`
 * calls typography the primary means of creating levels, and Flex offers no
 * font choice and no letter-spacing — only size, weight and colour. So the
 * amount takes high-emphasis charcoal at `lg` while the currency retreats to
 * muted `xs`, and the price stops reading at the same level as the name.
 */
export function productInfoContents(product: LineProduct): object[] {
  const contents: object[] = [
    {
      type: "text",
      text: product.name,
      size: "sm",
      weight: "bold",
      color: CARD_COLOR.primary,
      wrap: true,
      maxLines: 2,
    },
    {
      type: "text",
      margin: "8px",
      contents: [
        { type: "span", text: "NT$ ", size: "xs", color: CARD_COLOR.muted },
        {
          type: "span",
          text: amountText(product.price),
          size: "lg",
          weight: "bold",
          color: CARD_COLOR.primary,
        },
      ],
    },
  ];

  if (product.storeName) {
    contents.push({
      type: "text",
      margin: "4px",
      // Uppercase does nothing to a Chinese store name and turns a Latin one
      // into the editorial label the design system asks for. `maxLines` lets
      // LINE truncate rather than wrap a long name onto a second line.
      text: product.storeName.toUpperCase(),
      size: "xxs",
      color: CARD_COLOR.muted,
      maxLines: 1,
    });
  }

  return contents;
}

/**
 * A product name capped for a field LINE limits as one all-or-nothing check
 * on the whole message — postback `displayText` at 300 characters, flex
 * `altText` at 400 — where going over fails the entire send, not just this
 * piece of text. `products.name` is bare `text` in Postgres with no length
 * constraint, so nothing upstream stops a name from reaching either cap.
 *
 * The cap here is far below both LINE limits: a name past ~40 characters is
 * already unreadable on a LINE card, so clamping this early costs nothing
 * legible while removing the failure mode outright.
 */
const MAX_CLAMPED_NAME_CHARS = 40;

export function clampProductName(name: string): string {
  return name.length > MAX_CLAMPED_NAME_CHARS
    ? `${name.slice(0, MAX_CLAMPED_NAME_CHARS)}…`
    : name;
}
