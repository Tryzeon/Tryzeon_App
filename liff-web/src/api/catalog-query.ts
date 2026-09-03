export const SORT_OPTIONS = ["latest", "price_asc", "price_desc"] as const;
export type SortOption = typeof SORT_OPTIONS[number];

export interface SortParams {
  sortColumn: "created_at" | "price";
  sortAscending: boolean;
}

const SORT_MAP: Record<SortOption, SortParams> = {
  latest: { sortColumn: "created_at", sortAscending: false },
  price_asc: { sortColumn: "price", sortAscending: true },
  price_desc: { sortColumn: "price", sortAscending: false },
};

export function sortParams(sort: SortOption): SortParams {
  return SORT_MAP[sort];
}

export function searchParam(q: string): string | null {
  const trimmed = q.trim();
  return trimmed.length > 0 ? trimmed : null;
}

export class InvalidStoreIdError extends Error {
  constructor(raw: string) {
    super(`store must be a uuid: ${raw}`);
    this.name = "InvalidStoreIdError";
  }
}

const UUID_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/;

/**
 * Guards against a Postgres type error: a non-uuid string passed to a `uuid`
 * parameter ends the whole RPC in a 500, when the answer the caller wants is
 * simply "no such row".
 */
export function normalizeUuid(raw: string): string | null {
  const value = raw.trim().toLowerCase();
  return UUID_PATTERN.test(value) ? value : null;
}

/**
 * Throws on a malformed id rather than falling back to the site-wide catalog:
 * scanning one store's code and seeing every store's products is the worst
 * thing a store QR could do.
 */
export function parseStoreId(raw: string | undefined): string | null {
  if (raw === undefined) return null;
  const value = normalizeUuid(raw);
  if (value === null) throw new InvalidStoreIdError(raw);
  return value;
}
