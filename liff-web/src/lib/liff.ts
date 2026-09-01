import liff from "@line/liff";

let initialized = false;

export async function initAndLogin(): Promise<void> {
  if (!initialized) {
    await liff.init({ liffId: import.meta.env.VITE_LIFF_ID as string });
    initialized = true;
  }
  if (!liff.isLoggedIn()) {
    liff.login({ redirectUri: window.location.href });
    // login() redirects; this promise effectively never resolves further.
    await new Promise(() => {});
  }
}

/** LINE id_token。唯一的讀者是 `ensureSession()` —— 換 Supabase session 用。 */
export function getIdToken(): string {
  const token = liff.getIDToken();
  if (!token) throw new Error("no LINE id token (is `openid` scope enabled?)");
  return token;
}

/**
 * `purchase_link` is free text any authenticated store owner can write, not a
 * value the platform controls, so it must be checked before it reaches a
 * navigation sink rather than trusted as-is.
 */
export function isExternalUrl(url: string): boolean {
  try {
    const parsed = new URL(url);
    return parsed.protocol === "http:" || parsed.protocol === "https:";
  } catch {
    return false;
  }
}

/**
 * Opens a URL in the device browser rather than the LIFF in-app browser, so a
 * store's checkout keeps the shopper's existing session and cookies.
 */
export function openExternal(url: string): void {
  if (!isExternalUrl(url)) return;
  liff.openWindow({ url, external: true });
}

/**
 * 把一張結果圖當成圖片訊息送進使用者選的聊天室。
 *
 * 這同時是 LIFF 上的「儲存」—— webview 沒有相簿可以寫,傳回聊天室之後 LINE 自己
 * 就能存圖,而結果圖只有 7 天的簽章網址,離開這個 webview 就再也找不回來。
 *
 * shareTargetPicker 要在 LINE Developers Console 上開,而且在外部瀏覽器裡不存在,
 * 所以送之前一定要問過 [canShareToChat]。回傳 false 代表使用者按了取消。
 */
export function canShareToChat(): boolean {
  return liff.isApiAvailable("shareTargetPicker");
}

export async function shareImageToChat(imageUrl: string): Promise<boolean> {
  const result = await liff.shareTargetPicker([
    { type: "image", originalContentUrl: imageUrl, previewImageUrl: imageUrl },
  ]);
  return result !== undefined;
}
