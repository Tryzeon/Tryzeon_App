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

/** Opens in the device browser, so a store's checkout keeps its session and cookies. */
export function openExternal(url: string): void {
  if (!isExternalUrl(url)) return;
  liff.openWindow({ url, external: true });
}

/**
 * This doubles as "save" on LIFF — the webview has no photo library to write to,
 * whereas once an image is sent to a chat LINE can save it, and a result image
 * is only a 7-day signed URL that is unrecoverable once this webview is gone.
 *
 * shareTargetPicker has to be enabled in the LINE Developers Console and does
 * not exist in an external browser, so always ask [canShareToChat] before
 * sending. Returns false when the user cancels.
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
