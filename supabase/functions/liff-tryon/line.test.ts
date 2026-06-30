import { assertEquals, assertRejects } from "jsr:@std/assert";
import { LineAuthError, verifyLineIdToken } from "./line.ts";

function fakeFetch(status: number, jsonBody: unknown): typeof fetch {
  return ((_url: string | URL | Request, _init?: RequestInit) =>
    Promise.resolve(
      new Response(JSON.stringify(jsonBody), { status }),
    )) as typeof fetch;
}

Deno.test("verifyLineIdToken returns the profile on success", async () => {
  const f = fakeFetch(200, { sub: "U123", aud: "chan-1", name: "Eric", picture: "p" });
  const profile = await verifyLineIdToken("tok", "chan-1", f);
  assertEquals(profile, { sub: "U123", name: "Eric", picture: "p" });
});

Deno.test("verifyLineIdToken rejects when aud != channelId", async () => {
  const f = fakeFetch(200, { sub: "U123", aud: "OTHER" });
  await assertRejects(() => verifyLineIdToken("tok", "chan-1", f), LineAuthError);
});

Deno.test("verifyLineIdToken rejects on non-ok response", async () => {
  const f = fakeFetch(400, { error: "invalid_request" });
  await assertRejects(() => verifyLineIdToken("tok", "chan-1", f), LineAuthError);
});

Deno.test("verifyLineIdToken rejects when sub is missing", async () => {
  const f = fakeFetch(200, { aud: "chan-1" });
  await assertRejects(() => verifyLineIdToken("tok", "chan-1", f), LineAuthError);
});
