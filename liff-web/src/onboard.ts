export async function setAvatar(idToken: string, avatarBase64: string): Promise<void> {
  const resp = await fetch(import.meta.env.VITE_LIFF_AVATAR_URL as string, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ idToken, avatarBase64 }),
  });
  if (!resp.ok) {
    const data = await resp.json().catch(() => ({}));
    throw new Error(data.error ?? "set avatar failed");
  }
}
