import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { getAdminClient } from "../_shared/supabase.ts";
import { verifyLineSignature } from "./signature.ts";
import { makeLineApi } from "./line-api.ts";
import { getAvatarPath } from "../_shared/user-profile.ts";
import { hintMessage } from "./messages.ts";
import { handleImageMessage } from "./handler.ts";

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
  if (!channelSecret || !accessToken || !liffOnboardUrl) {
    console.error("line-webhook missing env (LINE_CHANNEL_SECRET/ACCESS_TOKEN/LIFF_ONBOARD_URL)");
    return new Response("Server misconfigured", { status: 500 });
  }

  const bodyText = await req.text();
  const signature = req.headers.get("x-line-signature");
  if (!(await verifyLineSignature(channelSecret, bodyText, signature))) {
    return new Response("Bad signature", { status: 401 });
  }

  const admin = getAdminClient();
  const line = makeLineApi(accessToken);

  let payload: { events?: unknown[] };
  try {
    payload = JSON.parse(bodyText);
  } catch {
    return new Response("Bad request", { status: 400 });
  }
  const events = Array.isArray(payload.events) ? payload.events : [];

  for (const ev of events as Array<Record<string, any>>) {
    if (ev.type !== "message" || ev.source?.type !== "user") continue;

    if (ev.message?.type === "image") {
      const task = handleImageMessage(
        { admin, line, liffOnboardUrl, getAvatarPath },
        { replyToken: ev.replyToken, sourceUserId: ev.source.userId, messageId: ev.message.id },
      );
      // Return 200 fast; finish generation + push in the background.
      if (typeof EdgeRuntime !== "undefined") EdgeRuntime.waitUntil(task);
      else await task;
    } else {
      // Non-image message: nudge with a free reply.
      await line.reply(ev.replyToken, [hintMessage()]).catch(() => {});
    }
  }

  return new Response("OK", { status: 200 });
});
