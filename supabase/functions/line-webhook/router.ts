/**
 * Which handler an incoming event belongs to, if any.
 *
 * An image is a garment to try on; text is a request for the chat agent; a
 * postback is a button we put on a card coming back. All three take far longer
 * than the webhook may, so all three are returned as a task the caller finishes
 * in the background and delivers with a push. Anything else — a sticker, a
 * blank line, a postback from a card an older deploy sent — has no handler, and
 * `null` says so.
 *
 * This lives beside the handlers rather than in `index.ts` because what counts
 * as a usable event is a rule about them, not about the transport: the text
 * normalization here and the length check in `chat-handler.ts` are two halves
 * of one answer, and `index.ts` is the one module in the feature with no test.
 */
import { SupabaseClient } from "jsr:@supabase/supabase-js@2";
import { getAvatarPath } from "../_shared/user-profile.ts";
import { handleImageTryon, handleProductTryon } from "./tryon-handler.ts";
import { handleTextMessage } from "./chat-handler.ts";
import { parsePostback } from "./postback.ts";
import { LineApi } from "./line-api.ts";
import type { ConversationStore } from "./conversation.ts";

export interface RouterDeps {
  admin: SupabaseClient;
  line: LineApi;
  liffOnboardUrl: string;
  imagesBaseUrl: string;
  conversations: ConversationStore;
}

export function routeEvent(
  deps: RouterDeps,
  // deno-lint-ignore no-explicit-any
  ev: Record<string, any>,
): Promise<void> | null {
  if (ev.type === "message") return routeMessage(deps, ev);
  if (ev.type === "postback") return routePostback(deps, ev);
  return null;
}

function requireSourceUserId(
  // deno-lint-ignore no-explicit-any
  ev: Record<string, any>,
): string | null {
  const id = ev.source?.userId;
  return typeof id === "string" && id.length > 0 ? id : null;
}

function routeMessage(
  deps: RouterDeps,
  // deno-lint-ignore no-explicit-any
  ev: Record<string, any>,
): Promise<void> | null {
  const { admin, line } = deps;
  const sourceUserId = requireSourceUserId(ev);
  if (sourceUserId === null) return null;

  if (ev.message?.type === "image") {
    return handleImageTryon(
      {
        admin,
        line,
        liffOnboardUrl: deps.liffOnboardUrl,
        conversations: deps.conversations,
        getAvatarPath,
      },
      { replyToken: ev.replyToken, sourceUserId, messageId: ev.message.id },
    );
  }

  if (ev.message?.type === "text") {
    const text = String(ev.message.text ?? "").trim();
    if (text) {
      return handleTextMessage(
        {
          admin,
          line,
          imagesBaseUrl: deps.imagesBaseUrl,
          conversations: deps.conversations,
        },
        { replyToken: ev.replyToken, sourceUserId, text },
      );
    }
  }

  return null;
}

function routePostback(
  deps: RouterDeps,
  // deno-lint-ignore no-explicit-any
  ev: Record<string, any>,
): Promise<void> | null {
  const postback = parsePostback(ev.postback?.data);
  if (postback === null) return null;

  const sourceUserId = requireSourceUserId(ev);
  if (sourceUserId === null) return null;

  return handleProductTryon(
    {
      admin: deps.admin,
      line: deps.line,
      liffOnboardUrl: deps.liffOnboardUrl,
      imagesBaseUrl: deps.imagesBaseUrl,
      conversations: deps.conversations,
      getAvatarPath,
    },
    {
      replyToken: ev.replyToken,
      sourceUserId,
      productId: postback.productId,
    },
  );
}
