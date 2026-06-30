import liff from "@line/liff";

let initialized = false;

export async function initAndLogin(): Promise<void> {
  if (!initialized) {
    await liff.init({ liffId: import.meta.env.VITE_LIFF_ID as string });
    initialized = true;
  }
  if (!liff.isLoggedIn()) {
    liff.login();
    // login() redirects; this promise effectively never resolves further.
    await new Promise(() => {});
  }
}

export function getIdToken(): string {
  const token = liff.getIDToken();
  if (!token) throw new Error("no LINE id token (is `openid` scope enabled?)");
  return token;
}
