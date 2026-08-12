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

/**
 * Opens a URL in the device browser rather than the LIFF in-app browser, so a
 * store's checkout keeps the shopper's existing session and cookies.
 */
export function openExternal(url: string): void {
  if (!isExternalUrl(url)) return;
  liff.openWindow({ url, external: true });
}
