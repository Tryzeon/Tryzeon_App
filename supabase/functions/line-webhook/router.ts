/**
 * Which handler an incoming event belongs to, if any.
 *
 * An image is a garment to try on; text is a request for the chat agent; a
 * postback is a button we put on a card coming back. All three take far longer
 * than the webhook may, so all three are returned as a task the caller finishes
 * in the background and delivers with a push. A follow is the exception: its
 * answer is one fixed message, so it is done by the time the task resolves.
 *
 * Something a sender did that we understood but cannot act on — a sticker, a
 * blank line, a card from a deploy that no longer exists — comes back as a task
 * too, one that nudges. `null` is therefore left meaning exactly one thing:
 * this was not a request at all (a `leave`, a group, a delivery receipt), so
 * answering it would be answering nobody.
 *
 * All of this lives beside the handlers rather than in `index.ts` because what
 * counts as a usable event is a rule about them, not about the transport: the
 * text normalization here and the length check in `chat-handler.ts` are two
 * halves of one answer. Keeping the two outcomes apart in the return value is
 * what lets that hold — `index.ts` once carried its own list of event kinds,
 * which had to be edited in step with this file every time the set changed, in
 * the one module in the feature with no test.
 */
import { SupabaseClient } from "jsr:@supabase/supabase-js@2";
import {
  handleImageTryon,
  handleProductTryon,
  handleWardrobeTryon,
} from "./tryon-handler.ts";
import { handleTextMessage } from "./chat-handler.ts";
import { parsePostback } from "./postback.ts";
import { hintMessage, welcomeMessage } from "./messages.ts";
import { LineApi } from "./line-api.ts";
import type { ConversationStore } from "./conversation.ts";

export interface RouterDeps {
  admin: SupabaseClient;
  line: LineApi;
  liffUrl: string;
  imagesBaseUrl: string;
  conversations: ConversationStore;
}

export function routeEvent(
  deps: RouterDeps,
  // deno-lint-ignore no-explicit-any
  ev: Record<string, any>,
): Promise<void> | null {
  if (ev.source?.type !== "user") return null;

  if (ev.type === "message") return routeMessage(deps, ev);
  if (ev.type === "postback") return routePostback(deps, ev);
  if (ev.type === "follow") return routeFollow(deps, ev);
  return null;
}

/**
 * The reply for something a sender did that we understood but cannot act on —
 * a sticker, a blank line, a card from a deploy that no longer exists.
 *
 * A task like any other, so the caller needs no second branch: `null` is left
 * meaning one thing only, that the event was not a request at all. A failure
 * here is cosmetic and swallowed, which is why it warns rather than throws.
 */
async function hint(
  deps: RouterDeps,
  // deno-lint-ignore no-explicit-any
  ev: Record<string, any>,
): Promise<void> {
  try {
    await deps.line.reply(ev.replyToken, [hintMessage()]);
  } catch (err) {
    console.warn("line-webhook hint reply failed:", err);
  }
}

/**
 * A new follower, greeted on the reply token.
 *
 * The only event here that needs no `source.userId`: nothing is read, written
 * or charged, so a sender who has not accepted the OA's terms — and whose id
 * LINE therefore withholds — still gets the welcome.
 *
 * It fires on an unblock as well as a first follow (`follow.isUnblocked` tells
 * them apart, but LINE does not guarantee that flag's accuracy). Both get the
 * same message: greeting a returning follower twice costs nothing, and
 * greeting a new one not at all is the failure this exists to fix.
 */
function routeFollow(
  deps: RouterDeps,
  // deno-lint-ignore no-explicit-any
  ev: Record<string, any>,
): Promise<void> {
  return deps.line.reply(ev.replyToken, [welcomeMessage()]);
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
): Promise<void> {
  const { admin, line } = deps;
  const sourceUserId = requireSourceUserId(ev);
  if (sourceUserId === null) return hint(deps, ev);

  if (ev.message?.type === "image") {
    return handleImageTryon(
      {
        admin,
        line,
        liffUrl: deps.liffUrl,
        conversations: deps.conversations,
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

  return hint(deps, ev);
}

function routePostback(
  deps: RouterDeps,
  // deno-lint-ignore no-explicit-any
  ev: Record<string, any>,
): Promise<void> {
  const postback = parsePostback(ev.postback?.data);
  if (postback === null) return hint(deps, ev);

  const sourceUserId = requireSourceUserId(ev);
  if (sourceUserId === null) return hint(deps, ev);

  switch (postback.kind) {
    case "product":
      return handleProductTryon(
        {
          admin: deps.admin,
          line: deps.line,
          liffUrl: deps.liffUrl,
          conversations: deps.conversations,
        },
        {
          replyToken: ev.replyToken,
          sourceUserId,
          productId: postback.productId,
        },
      );
    case "wardrobe":
      return handleWardrobeTryon(
        {
          admin: deps.admin,
          line: deps.line,
          liffUrl: deps.liffUrl,
          conversations: deps.conversations,
        },
        {
          replyToken: ev.replyToken,
          sourceUserId,
          wardrobeItemId: postback.wardrobeItemId,
        },
      );
  }
}
