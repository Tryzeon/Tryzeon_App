// 純函式：把一個請求分類成「哪一個 code」與「哪一種開啟環境」。與 Deno 的 IO
// 和 Supabase client 無關，所以可以單獨測試。

/**
 * 開啟環境。目前**不影響回應** —— 唯一用途是寫進 `link_events.source`。
 *
 * 它記的是「這次掃碼發生在哪裡」，而 line 與 web 的比例就是決定要不要做落地頁那一層
 * 的依據：非 LINE 環境無法靠 302 可靠進入 LIFF，得讓使用者點一下，而那一層值不值得
 * 做取決於那個比例有多大。bot 存在的理由是別讓預覽預抓稀釋那個比例。
 *
 * 真的做了落地頁之後，這同一個判斷就會回頭決定送達方式。
 */
export type Surface = "bot" | "line" | "web";

/** 與 migration 的 short_links_code_format check 同一份規則。 */
const CODE_PATTERN = /^[a-z0-9][a-z0-9-]{1,31}$/;

/**
 * Code 是路徑最後一段，小寫化後才比對。前綴刻意不檢查：呼叫端把 code 直接接在這支
 * 函式的端點路徑後面（`…/short-links/{code}`），函式不需要知道自己被掛在哪，也不需要
 * 知道使用者掃到的是哪個對外前綴。
 */
export function codeFromPathname(pathname: string): string | null {
  const segments = pathname.split("/").filter(Boolean);
  if (segments.length === 0) return null;
  const code = segments[segments.length - 1].toLowerCase();
  return CODE_PATTERN.test(code) ? code : null;
}

/**
 * Crawler 要先判，因為預覽預抓會偽裝成一般瀏覽器流量，計進掃碼數就把成效指標
 * 稀釋掉了。
 */
const BOT_PATTERN = /bot\b|crawler|spider|preview|facebookexternalhit|embedly|quora link/i;

export function detectSurface(userAgent: string | null): Surface {
  if (!userAgent) return "web";
  if (BOT_PATTERN.test(userAgent)) return "bot";
  if (/\bLine\//i.test(userAgent)) return "line";
  return "web";
}

/** Best-effort OS，只作分析用。 */
export function platformFromUserAgent(userAgent: string | null): string {
  if (!userAgent) return "other";
  if (/android/i.test(userAgent)) return "android";
  if (/iphone|ipad|ipod/i.test(userAgent)) return "ios";
  return "other";
}

/**
 * Best-effort 取得來源 App。順序重要：先比對最專屬的 token（Instagram 與 Messenger
 * 各有自己的標記，但也間接帶著 Facebook 的 FBAN/FBAV）。偵測不到時回 null ——
 * 例如連結被複製到 Safari 開啟 —— 絕不猜。
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
