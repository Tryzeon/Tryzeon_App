// 目錄查詢的取值範圍。sort 是白名單而不是 RPC 的欄位名,所以畫面上的字彙不會
// 洩漏 list_shop_products 的詞彙。原本住在 liff-catalog/query.ts,那個 function
// 沒有了之後,同一份規則跟著呼叫端搬到瀏覽器。
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

/** 搜尋字串。修剪後空字串等於沒有條件,RPC 那邊要的是 null。 */
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
 * 路徑上的 id,正規化成小寫;不是 uuid 就是 null。
 *
 * 擋的是 Postgres 的型別錯誤:一個非 uuid 的字串送進 `uuid` 參數會讓整支 RPC 以
 * 500 收場,而呼叫端要的答案其實是「沒有這筆」。
 */
export function normalizeUuid(raw: string): string | null {
  const value = raw.trim().toLowerCase();
  return UUID_PATTERN.test(value) ? value : null;
}

/**
 * 路徑上的店家 id,正規化成小寫。
 *
 * 沒有 store 區段回 null(全站目錄);有但格式不對就拋。悄悄退回全站目錄是店家
 * QR 最不該有的行為 —— 掃了某家店的碼卻看到所有店的商品。這個檢查原本在
 * liff-catalog 的 query parser 裡擋 Postgres 型別錯誤,現在它擋的是那件事。
 */
export function parseStoreId(raw: string | undefined): string | null {
  if (raw === undefined) return null;
  const value = normalizeUuid(raw);
  if (value === null) throw new InvalidStoreIdError(raw);
  return value;
}
