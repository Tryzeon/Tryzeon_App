import type { Surface } from "./surface.ts";

/**
 * 已實作的開啟方式。加入 `web` / `app` 時，migration 的
 * `short_links_open_with_check` 也要同步放寬。
 */
const OPEN_WITH = ["liff"] as const;

export type OpenWith = typeof OPEN_WITH[number];

export function isOpenWith(value: unknown): value is OpenWith {
  return typeof value === "string" && (OPEN_WITH as readonly string[]).includes(value);
}

export interface DestinationConfig {
  liffUrl: string | null;
}

/** 回傳 null 表示這種開啟方式所需的設定沒給 —— 呼叫端據此回 500。 */
export function buildStoreDestination(
  openWith: OpenWith,
  storeId: string,
  config: DestinationConfig,
): string | null {
  switch (openWith) {
    case "liff":
      return config.liffUrl === null
        ? null
        : `${config.liffUrl.replace(/\/+$/, "")}/store/${storeId}`;
    default: {
      const unhandled: never = openWith;
      throw new Error(`unhandled open_with: ${unhandled}`);
    }
  }
}

/**
 * 為什麼不是一律 302：liff 的目的地是 LIFF URL，而 LIFF URL 是 iOS universal link。
 * Apple 的 DTS 明講 301/302 導向 universal link 在 iOS 18.3 之後不再開啟 App
 * （developer.apple.com/forums/thread/780496），LINE 自己也不保證外部瀏覽器能喚起
 * LIFF，並建議改由使用者點擊觸發
 * （developers.line.biz/en/tips/2026/05/07/line-launch-issue/）。
 *
 * 所以請不要把 interstitial 改成自動跳轉 —— 那條路在 iOS 上是壞的。
 */
export type Delivery = "redirect" | "interstitial";

export function deliveryFor(openWith: OpenWith, surface: Surface): Delivery {
  switch (openWith) {
    case "liff":
      // crawler 也走 interstitial —— 預覽卡要抓得到 OG tag。
      return surface === "line" ? "redirect" : "interstitial";
    default: {
      const unhandled: never = openWith;
      throw new Error(`unhandled open_with: ${unhandled}`);
    }
  }
}
