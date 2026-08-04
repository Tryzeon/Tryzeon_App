export interface LineProfile {
  sub: string;
  name?: string;
  picture?: string;
}

export class LineAuthError extends Error {}

const LINE_VERIFY_URL = "https://api.line.me/oauth2/v2.1/verify";

/**
 * Verifies a LINE id_token against LINE's verify endpoint. LINE performs the
 * signature + expiry checks server-side, so we only trust a 200 + matching aud.
 * `fetchFn` is injectable for testing.
 */
export async function verifyLineIdToken(
  idToken: string,
  channelId: string,
  nonce?: string,
  fetchFn: typeof fetch = fetch,
): Promise<LineProfile> {
  const params = new URLSearchParams({ id_token: idToken, client_id: channelId });
  if (nonce) params.set("nonce", nonce);

  const resp = await fetchFn(LINE_VERIFY_URL, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: params,
  });

  if (!resp.ok) {
    throw new LineAuthError(`LINE token verification failed (${resp.status})`);
  }

  const payload = (await resp.json()) as Record<string, unknown>;

  if (payload.aud !== channelId) {
    throw new LineAuthError("LINE token audience mismatch");
  }
  if (typeof payload.sub !== "string" || payload.sub.length === 0) {
    throw new LineAuthError("LINE token missing sub");
  }

  return {
    sub: payload.sub,
    name: typeof payload.name === "string" ? payload.name : undefined,
    picture: typeof payload.picture === "string" ? payload.picture : undefined,
  };
}
