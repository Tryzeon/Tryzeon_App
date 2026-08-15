import { SupabaseClient } from "jsr:@supabase/supabase-js@2";
import { isUuid } from "../text.ts";
import { ValidationError } from "./errors.ts";
import { LIMITS } from "./types.ts";
import type { ResolvedGarment } from "./types.ts";

/** Raw wardrobe columns needed to build a try-on garment. */
export interface WardrobeGarmentRow {
  image_path: unknown;
  category: unknown;
  tags: unknown;
}

function trimmedString(value: unknown): string {
  return typeof value === "string" ? value.trim() : "";
}

/**
 * Model-facing garment description built from a wardrobe row.
 *
 * The category goes in as its raw enum code. The one enum→Chinese map in this
 * codebase belongs to the LINE card, which dresses rows for people; a second
 * copy here would be one more thing to keep in step, and
 * `buildProductGarmentDetail` passes DB text through for the same reason.
 */
export function buildWardrobeGarmentDetail(
  row: WardrobeGarmentRow,
): string | undefined {
  const parts: string[] = [];

  const category = trimmedString(row.category);
  if (category) parts.push(`Category: ${category}`);

  const tags = Array.isArray(row.tags)
    ? row.tags.map(trimmedString).filter((t) => t.length > 0)
    : [];
  if (tags.length > 0) parts.push(`Tags: ${tags.join(", ")}`);

  if (parts.length === 0) return undefined;
  return parts.join(". ").slice(0, LIMITS.MAX_GARMENT_DETAIL_LENGTH);
}

/**
 * Resolves a wardrobe item reference to trusted garment material, bound to the
 * user it belongs to.
 *
 * The ownership filter is why this lives in the core and not in each adapter:
 * the client it is handed is whatever the adapter passed to `runTryonJob`, and
 * an adapter with no RLS beneath it — the LINE webhook is one — would otherwise
 * have to remember the check on every path, forever.
 *
 * A row that is gone and a row belonging to someone else raise the SAME error,
 * word for word. Telling them apart would make this an oracle for probing
 * whether an id sits in another user's wardrobe, so the message carries nothing
 * read from the database.
 */
export async function resolveWardrobeGarment(
  client: SupabaseClient,
  userId: string,
  wardrobeItemId: string,
): Promise<ResolvedGarment> {
  // Rejected here rather than at the query: Postgres answers a malformed uuid
  // with a 22P02 that would surface as a server fault, not a bad request.
  if (!isUuid(wardrobeItemId)) {
    throw new ValidationError(`invalid wardrobeItemId: ${wardrobeItemId}`);
  }

  const { data, error } = await client
    .from("wardrobe_items")
    .select("image_path, category, tags")
    .eq("id", wardrobeItemId)
    .eq("user_id", userId)
    .maybeSingle();

  if (error) {
    throw new Error(`wardrobe item lookup failed: ${error.message}`);
  }

  // One check for four outcomes — no row, someone else's row, a row whose
  // path is blank, a row whose path points outside the owner's folder —
  // because all four mean the same thing to a caller and separating them is
  // what would leak.
  const path = trimmedString(data?.image_path);
  // The row is the caller's, but `image_path` is client-written free text, so
  // owning the row is not owning the object. Same folder rule the storage
  // policy enforces, restated here because the LINE adapter reads through a
  // client that has no policy beneath it.
  if (!path || !path.startsWith(`${userId}/`)) {
    throw new ValidationError(
      `no wardrobe item for wardrobeItemId: ${wardrobeItemId}`,
    );
  }

  const detail = buildWardrobeGarmentDetail(data as WardrobeGarmentRow);
  return detail === undefined
    ? { images: [{ path }] }
    : { images: [{ path }], detail };
}
