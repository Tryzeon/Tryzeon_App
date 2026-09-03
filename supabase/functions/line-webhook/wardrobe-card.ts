import { fetchRowsByIds } from "../_shared/chat/hydrate.ts";
import { textArrayValues } from "../_shared/text.ts";
import { WARDROBE_IMAGES_BUCKET } from "../_shared/storage.ts";
import { CARD_COLOR } from "./card-kit.ts";
import type { Enums, Tables } from "../_shared/database.types.ts";
import type { DbClient } from "../_shared/supabase.ts";

export const WARDROBE_CARD_SELECT = "id, image_path, category, tags";

export type WardrobeCardRow = Pick<
  Tables<"wardrobe_items">,
  "id" | "image_path" | "category" | "tags"
>;

/**
 * Keyed by the generated enum so a migration that adds a value fails the build
 * here. The `?? code` fallback below survives it anyway: a deployed function can
 * be reading a schema newer than the types it was built against.
 */
const CATEGORY_LABEL: Record<Enums<"wardrobe_category">, string> = {
  top: "上衣",
  bottoms: "下身",
  outerwear: "外套",
  sets: "套裝",
  others: "其他",
};

const MAX_TAGS = 3;

/**
 * `maxLines: 1` truncates the display, but the bytes still count toward the Flex
 * message's overall size limit, and tags are free text with no length constraint
 * in the column.
 */
const MAX_TAG_LINE_CHARS = 40;

export interface WardrobeItemInfo {
  id: string;
  categoryLabel: string;
  tags: string[];
}

export interface LineWardrobeItem extends WardrobeItemInfo {
  imageUrl: string;
}

export function toWardrobeItemInfo(row: WardrobeCardRow): WardrobeItemInfo {
  return {
    id: row.id,
    categoryLabel: CATEGORY_LABEL[row.category] ?? row.category,
    tags: textArrayValues(row.tags).filter((t) => t.length > 0).slice(0, MAX_TAGS),
  };
}

export function toLineWardrobeItem(
  row: WardrobeCardRow,
  signedUrl: string | undefined,
): LineWardrobeItem | null {
  if (!signedUrl) return null;
  return { ...toWardrobeItemInfo(row), imageUrl: signedUrl };
}

export function tagLine(tags: string[]): string {
  const line = tags.map((t) => `#${t}`).join(" ");
  return line.length > MAX_TAG_LINE_CHARS
    ? `${line.slice(0, MAX_TAG_LINE_CHARS)}…`
    : line;
}

/** Derived rather than re-listed so the two cannot drift. */
const NOUN_LABELS = new Set(
  Object.entries(CATEGORY_LABEL)
    .filter(([code]) => code !== "others")
    .map(([, label]) => label),
);

/**
 * `其他` is a bucket, not a noun, and an unmapped code is not a word at all —
 * both become `單品`. The card's own headline keeps the raw label, where a bucket
 * name reads fine standing alone.
 */
export function garmentNoun(categoryLabel: string): string {
  return NOUN_LABELS.has(categoryLabel) ? categoryLabel : "單品";
}

export function wardrobeInfoContents(item: WardrobeItemInfo): object[] {
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
 * Seven days, not the app's hour: a LINE message is scrolled back to, and an
 * expired URL is a card that renders as a hole. Deliberately not shared with
 * `_shared/r2.ts`'s identical constant — that is R2's signing window, this is
 * Supabase Storage's.
 */
const SIGNED_URL_TTL_SECONDS = 604800;

/**
 * One batch call rather than one per item. A row the service could not sign is
 * simply absent, which `toLineWardrobeItem` turns into a dropped card; a failure
 * of the call itself throws, because that is a server fault rather than a
 * missing item.
 */
async function signImageUrls(
  admin: DbClient,
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
 * `userId` bounds the query, and that is a security property rather than a
 * filter: this path runs on the admin client with no RLS beneath it, so without
 * the `.eq` an id the model quoted could name another sender's item.
 * `fetchProductRows` needs no such parameter only because the catalog is public.
 */
export async function fetchWardrobeRows(
  admin: DbClient,
  userId: string,
  ids: string[],
): Promise<Map<string, LineWardrobeItem>> {
  const raw = await fetchRowsByIds(
    admin.from("wardrobe_items").select(WARDROBE_CARD_SELECT).eq("user_id", userId),
    ids,
  );

  const urls = await signImageUrls(
    admin,
    [...raw.values()].map((r) => r.image_path).filter((p) => typeof p === "string" && p.length > 0),
  );

  const rows = new Map<string, LineWardrobeItem>();
  for (const [id, row] of raw) {
    const item = toLineWardrobeItem(row, urls.get(row.image_path));
    if (item) rows.set(id, item);
  }
  return rows;
}

/**
 * No signed URL, unlike `fetchProductInfo`: a try-on result card's hero is the
 * generated image, and a signing failure would refuse a try-on the core could
 * have completed.
 *
 * Bound to `userId` like every wardrobe read. `resolveWardrobeGarment` binds it
 * again inside the job; this one exists so that "gone, or never yours" becomes a
 * sentence before any quota is charged.
 */
export async function fetchWardrobeItemInfo(
  admin: DbClient,
  userId: string,
  wardrobeItemId: string,
): Promise<WardrobeItemInfo | null> {
  const { data, error } = await admin
    .from("wardrobe_items")
    .select(WARDROBE_CARD_SELECT)
    .eq("id", wardrobeItemId)
    .eq("user_id", userId)
    .maybeSingle();

  if (error) {
    throw new Error(`wardrobe item lookup failed: ${error.message}`);
  }
  return data ? toWardrobeItemInfo(data) : null;
}
