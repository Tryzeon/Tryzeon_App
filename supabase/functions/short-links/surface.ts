/**
 * 開啟環境。目前**不影響回應** —— 唯一用途是寫進 `link_events.source`。line 與 web
 * 的比例就是決定要不要做落地頁那一層的依據：非 LINE 環境無法靠 302 可靠進入 LIFF，
 * 得讓使用者點一下，而那一層值不值得做取決於那個比例有多大。bot 存在的理由是別讓
 * 預覽預抓稀釋那個比例。
 */
export type Surface = "bot" | "line" | "web";

/** 與 migration 的 short_links_code_format check 同一份規則。 */
const CODE_PATTERN = /^[a-z0-9][a-z0-9-]{1,31}$/;

/** 前綴刻意不檢查：函式不需要知道自己被掛在哪個對外路徑下。 */
export function codeFromPathname(pathname: string): string | null {
  const segments = pathname.split("/").filter(Boolean);
  if (segments.length === 0) return null;
  const code = segments[segments.length - 1].toLowerCase();
  return CODE_PATTERN.test(code) ? code : null;
}

/** Crawler 要先判：預覽預抓會偽裝成一般瀏覽器流量，計進掃碼數就稀釋了成效指標。 */
const BOT_PATTERN = /bot\b|crawler|spider|preview|facebookexternalhit|embedly|quora link/i;

export function detectSurface(userAgent: string | null): Surface {
  if (!userAgent) return "web";
  if (BOT_PATTERN.test(userAgent)) return "bot";
  if (/\bLine\//i.test(userAgent)) return "line";
  return "web";
}

export function platformFromUserAgent(userAgent: string | null): string {
  if (!userAgent) return "other";
  if (/android/i.test(userAgent)) return "android";
  if (/iphone|ipad|ipod/i.test(userAgent)) return "ios";
  return "other";
}

/**
 * 順序重要：先比對最專屬的 token —— Instagram 與 Messenger 各有自己的標記，但也
 * 間接帶著 Facebook 的 FBAN/FBAV。
 */
export function channelFromUserAgent(userAgent: string | null): string | null {
  if (!userAgent) return null;
  if (/Instagram/i.test(userAgent)) return "instagram";
  if (/\bLine\//i.test(userAgent)) return "line";
  if (/Messenger|Orca-Android/i.test(userAgent)) return "messenger";
  if (/Barcelona/i.test(userAgent)) return "threads"; // Threads codename
  if (/FBAN|FBAV|FB_IAB/i.test(userAgent)) return "facebook";
  return null;
}
