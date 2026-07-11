const REPLY_URL = "https://api.line.me/v2/bot/message/reply";
const PUSH_URL = "https://api.line.me/v2/bot/message/push";
const contentUrl = (id: string) => `https://api-data.line.me/v2/bot/message/${id}/content`;

export interface LineApi {
  reply(replyToken: string, messages: object[]): Promise<void>;
  push(to: string, messages: object[]): Promise<void>;
  getContent(messageId: string): Promise<Uint8Array>;
}

export function makeLineApi(accessToken: string, fetchFn: typeof fetch = fetch): LineApi {
  const authHeaders = { "Authorization": `Bearer ${accessToken}` };
  return {
    async reply(replyToken, messages) {
      const r = await fetchFn(REPLY_URL, {
        method: "POST",
        headers: { ...authHeaders, "Content-Type": "application/json" },
        body: JSON.stringify({ replyToken, messages }),
      });
      if (!r.ok) throw new Error(`LINE reply failed ${r.status}: ${await r.text()}`);
    },
    async push(to, messages) {
      const r = await fetchFn(PUSH_URL, {
        method: "POST",
        headers: { ...authHeaders, "Content-Type": "application/json" },
        body: JSON.stringify({ to, messages }),
      });
      if (!r.ok) throw new Error(`LINE push failed ${r.status}: ${await r.text()}`);
    },
    async getContent(messageId) {
      const r = await fetchFn(contentUrl(messageId), { headers: authHeaders });
      if (!r.ok) throw new Error(`LINE content failed ${r.status}`);
      return new Uint8Array(await r.arrayBuffer());
    },
  };
}
