/**
 * What one wardrobe card is made of.
 *
 * `product-card.ts`'s sibling: same job, different table. A wardrobe item has
 * no name and no price, so the three lines a product card shows become the
 * category, the tags, and a fixed "你的衣櫃" — which is also what tells the two
 * kinds of card apart when they sit in one carousel.
 */
import { SupabaseClient } from "jsr:@supabase/supabase-js@2";
import { fetchRowsByIds } from "../_shared/chat/hydrate.ts";
import type { ContentBlock } from "../_shared/chat/index.ts";
import { WARDROBE_IMAGES_BUCKET } from "../_shared/storage.ts";
import { CARD_COLOR } from "./card-kit.ts";

export const WARDROBE_CARD_SELECT = "id, image_path, category, tags";

/**
 * Labels for the `wardrobe_category` enum. Its current value set was fixed in
 * `20260616120000_remap_wardrobe_category_enum.sql`.
 */
const CATEGORY_LABEL: Record<string, string> = {
  top: "上衣",
  bottoms: "下身",
  outerwear: "外套",
  sets: "套裝",
  others: "其他",
};

/** Tags one card shows. Past three the line stops being scannable. */
const MAX_TAGS = 3;

/**
 * Cap on the tag line. `maxLines: 1` truncates the display, but the bytes
 * still count toward the Flex message's overall size limit, and tags are
 * free text from `LabelTagger` with no length constraint in the column.
 */
const MAX_TAG_LINE_CHARS = 40;

/** A wardrobe item reduced to what one card displays. */
export interface LineWardrobeItem {
  id: string;
  /** Signed URL of the item's image; wardrobe images are not public. */
  imageUrl: string;
  categoryLabel: string;
  tags: string[];
}

/**
 * One wardrobe row as a card's worth of fields, or null when its image could
 * not be signed — a card whose image is missing is one you cannot see, the same
 * rule `toLineProduct` applies to a product with no image.
 */
export function toLineWardrobeItem(
  // deno-lint-ignore no-explicit-any
  row: Record<string, any>,
  signedUrl: string | undefined,
): LineWardrobeItem | null {
  if (!signedUrl) return null;

  const category = String(row.category ?? "");
  const tags = Array.isArray(row.tags) ? row.tags : [];

  return {
    id: String(row.id),
    imageUrl: signedUrl,
    categoryLabel: CATEGORY_LABEL[category] ?? category,
    tags: tags
      .filter((t: unknown): t is string => typeof t === "string" && t.length > 0)
      .slice(0, MAX_TAGS),
  };
}

/** The tags as the one line a card shows them on. */
export function tagLine(tags: string[]): string {
  const line = tags.map((t) => `#${t}`).join(" ");
  return line.length > MAX_TAG_LINE_CHARS
    ? `${line.slice(0, MAX_TAG_LINE_CHARS)}…`
    : line;
}

/**
 * The category / tags / source lines the card shows.
 *
 * A tag-less item drops its middle line entirely rather than rendering an empty
 * one, the way a product with no store shows two lines instead of three.
 */
export function wardrobeInfoContents(item: LineWardrobeItem): object[] {
  const contents: object[] = [
    {
      type: "text",
      text: item.categoryLabel,
      size: "sm",
      weight: "bold",
      color: CARD_COLOR.primary,
      wrap: true,
      maxLines: 2,
    },
  ];

  if (item.tags.length > 0) {
    contents.push({
      type: "text",
      margin: "8px",
      text: tagLine(item.tags),
      size: "xs",
      color: CARD_COLOR.muted,
      maxLines: 1,
    });
  }

  contents.push({
    type: "text",
    margin: "4px",
    text: "你的衣櫃",
    size: "xxs",
    color: CARD_COLOR.muted,
    maxLines: 1,
  });

  return contents;
}

/**
 * How long a card's image URL stays good.
 *
 * Seven days, not the app's hour: a LINE message is scrolled back to, and an
 * expired URL is a card that renders as a hole. Deliberately not shared with
 * `_shared/r2.ts`'s identical constant — that one is R2's signing window and
 * this one is Supabase Storage's, and their being equal today is a coincidence
 * rather than a rule.
 */
const SIGNED_URL_TTL_SECONDS = 604800;

/**
 * Signed URLs for wardrobe images, keyed by storage path.
 *
 * One batch call rather than one per item. A row the service could not sign is
 * simply absent, which `toLineWardrobeItem` turns into a dropped card; a
 * failure of the call itself throws, because that is a server fault rather than
 * a missing item.
 */
async function signImageUrls(
  admin: SupabaseClient,
  paths: string[],
): Promise<Map<string, string>> {
  const urls = new Map<string, string>();
  if (paths.length === 0) return urls;

  const { data, error } = await admin.storage
    .from(WARDROBE_IMAGES_BUCKET)
    .createSignedUrls(paths, SIGNED_URL_TTL_SECONDS);
  if (error) throw new Error(`wardrobe image signing failed: ${error.message}`);

  for (const entry of data ?? []) {
    if (entry.path && entry.signedUrl) urls.set(entry.path, entry.signedUrl);
  }
  return urls;
}

/**
 * The referenced wardrobe items as the fields a card shows, keyed by id — the
 * wardrobe half of `AnswerRows`.
 *
 * `userId` bounds the query, and that is a security property rather than a
 * filter: this path runs on the admin client with no RLS beneath it, so without
 * the `.eq` an id the model quoted could name another sender's item.
 * `fetchProductRows` takes no such parameter because the catalog is public —
 * the asymmetry is the point, and closing it would open a leak.
 *
 * Two round trips, both batched: the rows, then every image signed at once.
 */
export async function fetchWardrobeRows(
  admin: SupabaseClient,
  userId: string,
  ids: string[],
): Promise<Map<string, ContentBlock>> {
  // deno-lint-ignore no-explicit-any
  const raw: Map<string, Record<string, any>> = await fetchRowsByIds(
    admin.from("wardrobe_items").select(WARDROBE_CARD_SELECT).eq("user_id", userId),
    ids,
  );

  const urls = await signImageUrls(
    admin,
    [...raw.values()]
      .map((r) => r.image_path)
      .filter((p): p is string => typeof p === "string" && p.length > 0),
  );

  const rows = new Map<string, ContentBlock>();
  for (const [id, row] of raw) {
    const item = toLineWardrobeItem(row, urls.get(row.image_path));
    if (item) rows.set(id, item);
  }
  return rows;
}
