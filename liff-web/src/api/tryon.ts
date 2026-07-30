import { readJson } from "./errors";

/** Server code meaning the user has no model photo on file yet. */
export const NO_AVATAR = "NO_AVATAR";

/** Runs a try-on against the user's stored model photo. Returns the result URL. */
export async function callTryon(idToken: string, productId: string): Promise<string> {
  const data = await readJson(
    await fetch(import.meta.env.VITE_LIFF_TRYON_URL as string, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ idToken, productId }),
    }),
  );
  if (typeof data.imageUrl !== "string" || data.imageUrl.length === 0) {
    throw new Error("tryon response missing imageUrl");
  }
  return data.imageUrl;
}
