// The catalog endpoint's public query surface, decoded into list_shop_products
// parameters. `sort` is a whitelisted enum rather than the RPC's column name so
// the wire format does not leak the RPC's vocabulary — and so an unknown value
// is a rejected request instead of a silent fallback.
import { ValidationError } from "../_shared/validation.ts";

export const SORT_OPTIONS = ["latest", "price_asc", "price_desc"] as const;
export type SortOption = typeof SORT_OPTIONS[number];

export interface CatalogQuery {
  offset: number;
  searchQuery: string | null;
  storeId: string | null;
  sortColumn: "created_at" | "price";
  sortAscending: boolean;
}

type SortPair = Pick<CatalogQuery, "sortColumn" | "sortAscending">;

const SORT_MAP: Record<SortOption, SortPair> = {
  latest: { sortColumn: "created_at", sortAscending: false },
  price_asc: { sortColumn: "price", sortAscending: true },
  price_desc: { sortColumn: "price", sortAscending: false },
};

function isSortOption(value: string): value is SortOption {
  return (SORT_OPTIONS as readonly string[]).includes(value);
}

const UUID_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/;

/**
 * 店家篩選。格式先驗證再往下傳:一個不是 uuid 的字串到了 RPC 只會變成 Postgres
 * 的型別錯誤與 500,在這裡擋掉就是一個誠實的 400。
 */
function parseStoreId(raw: string | null): string | null {
  if (raw === null) return null;
  const value = raw.trim().toLowerCase();
  if (!UUID_PATTERN.test(value)) {
    throw new ValidationError("store must be a uuid");
  }
  return value;
}

/** Decodes the request URL's query string. Raises on an unknown `sort`. */
export function parseCatalogQuery(url: URL): CatalogQuery {
  const offset = Math.max(
    0,
    parseInt(url.searchParams.get("offset") ?? "0", 10) || 0,
  );

  const q = (url.searchParams.get("q") ?? "").trim();

  const sort = url.searchParams.get("sort") ?? "latest";
  if (!isSortOption(sort)) {
    throw new ValidationError(`sort must be one of: ${SORT_OPTIONS.join(", ")}`);
  }

  return {
    offset,
    searchQuery: q.length > 0 ? q : null,
    storeId: parseStoreId(url.searchParams.get("store")),
    ...SORT_MAP[sort],
  };
}
