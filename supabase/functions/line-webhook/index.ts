import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { getAdminClient } from "../_shared/supabase.ts";
import { parseJsonObject } from "../_shared/validation.ts";
import { verifyLineSignature } from "./signature.ts";
import { makeLineApi } from "./line-api.ts";
import { hintMessage } from "./messages.ts";
import { routeEvent } from "./router.ts";

// EdgeRuntime.waitUntil keeps the function warm for the ~30s generation after
// the 200 has been returned. Declared here for the Deno type checker.
declare const EdgeRuntime: { waitUntil(p: Promise<unknown>): void } | undefined;

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  const channelSecret = Deno.env.get("LINE_CHANNEL_SECRET");
  const accessToken = Deno.env.get("LINE_CHANNEL_ACCESS_TOKEN");
  const liffOnboardUrl = Deno.env.get("LIFF_ONBOARD_URL");
  const imagesBaseUrl = Deno.env.get("R2_PUBLIC_IMAGES_BASE_URL");
  if (!channelSecret || !accessToken || !liffOnboardUrl || !imagesBaseUrl) {
    console.error(
      "line-webhook missing env (LINE_CHANNEL_SECRET/ACCESS_TOKEN/" +
        "LIFF_ONBOARD_URL/R2_PUBLIC_IMAGES_BASE_URL)",
    );
    return new Response("Server misconfigured", { status: 500 });
  }

  const bodyText = await req.text();
  const signature = req.headers.get("x-line-signature");
  if (!(await verifyLineSignature(channelSecret, bodyText, signature))) {
    return new Response("Bad signature", { status: 401 });
  }

  let events: unknown[];
  try {
    const payload = parseJsonObject(bodyText);
    events = Array.isArray(payload.events) ? payload.events : [];
  } catch {
    return new Response("Bad request", { status: 400 });
  }

  const admin = getAdminClient();
  const line = makeLineApi(accessToken);

  for (const ev of events as Array<Record<string, any>>) {
    if (ev.source?.type !== "user") continue;
    if (ev.type !== "message" && ev.type !== "postback") continue;

    const task = routeEvent({ admin, line, liffOnboardUrl, imagesBaseUrl }, ev);
    if (task === null) {
      // Nothing we handle (a sticker, a blank line): nudge with a free reply.
      await line.reply(ev.replyToken, [hintMessage()]).catch((err) => {
        console.warn("line-webhook hint reply failed:", err);
      });
      continue;
    }

    // Return 200 fast; finish the work + push in the background.
    const guardedTask = task.catch((err) => {
      console.error("line-webhook background task failed:", err);
    });
    if (typeof EdgeRuntime !== "undefined") EdgeRuntime.waitUntil(guardedTask);
    else await guardedTask;
  }

  return new Response("OK", { status: 200 });
});
