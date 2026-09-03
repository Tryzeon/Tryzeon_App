// sort 是白名單而不是 RPC 的欄位名,所以畫面上的字彙不會洩漏
// list_shop_products 的詞彙。
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
 * 擋的是 Postgres 的型別錯誤:一個非 uuid 的字串送進 `uuid` 參數會讓整支 RPC 以
 * 500 收場,而呼叫端要的答案其實是「沒有這筆」。
 */
export function normalizeUuid(raw: string): string | null {
  const value = raw.trim().toLowerCase();
  return UUID_PATTERN.test(value) ? value : null;
}

/**
 * 格式不對就拋,不退回全站目錄:掃了某家店的碼卻看到所有店的商品,是店家 QR 最
 * 不該有的行為。
 */
export function parseStoreId(raw: string | undefined): string | null {
  if (raw === undefined) return null;
  const value = normalizeUuid(raw);
  if (value === null) throw new InvalidStoreIdError(raw);
  return value;
}
