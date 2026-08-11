// 一個短連結要把使用者送去哪裡。
//
// 目的地種類是連結自己的屬性（`short_links.open_with`），不是掃碼環境推導出來的 ——
// 一個連結只支援一種開啟方式，環境只決定「能不能直接 302」。所以每一種開啟方式需要
// 的設定也各自獨立：缺 LIFF_URL 只會讓 liff 型的連結失敗，不該讓整支函式失效。

/**
 * 已實作的開啟方式。加入 `web` / `app` 時，把值加進這個陣列 —— `buildDestination` 的
 * switch 會因為缺少分支而編譯失敗，強制你把它處理掉，而不是靜默回傳 null。
 * migration 的 `short_links_open_with_check` 也要同步放寬。
 */
const OPEN_WITH = ["liff"] as const;

export type OpenWith = typeof OPEN_WITH[number];

export function isOpenWith(value: unknown): value is OpenWith {
  return typeof value === "string" && (OPEN_WITH as readonly string[]).includes(value);
}

/** 各開啟方式所需的設定。每一項獨立，缺一項只影響對應的那一種連結。 */
export interface DestinationConfig {
  /** LIFF 入口，例如 `https://liff.line.me/{liffId}`。 */
  liffUrl: string | null;
}

/**
 * 算出店家連結的目的地。回傳 null 表示這種開啟方式所需的設定沒給 —— 呼叫端據此回
 * 500，而不是把使用者導到一個壞掉的網址。
 */
export function buildStoreDestination(
  openWith: OpenWith,
  storeId: string,
  config: DestinationConfig,
): string | null {
  switch (openWith) {
    case "liff":
      return config.liffUrl === null
        ? null
        // 結尾斜線要吃掉：liffUrl 是人工設定的環境變數。
        : `${config.liffUrl.replace(/\/+$/, "")}/store/${storeId}`;
    default: {
      const unhandled: never = openWith;
      throw new Error(`unhandled open_with: ${unhandled}`);
    }
  }
}
