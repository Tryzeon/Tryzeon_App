import { readJson } from "./errors";

/** Stores the user's model photo; every later try-on uses it. */
export async function setAvatar(idToken: string, avatarBase64: string): Promise<void> {
  await readJson(
    await fetch(import.meta.env.VITE_LIFF_AVATAR_URL as string, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ idToken, avatarBase64 }),
    }),
  );
}
