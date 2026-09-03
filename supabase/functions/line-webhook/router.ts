/**
 * `null` means exactly one thing: this was not a request at all (a `leave`, a
 * group, a delivery receipt). Something a sender did that we understood but
 * cannot act on comes back as a task too, one that nudges.
 */
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
import type { DbClient } from "../_shared/supabase.ts";

export interface RouterDeps {
  admin: DbClient;
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
 * The only event here that needs no `source.userId`: nothing is read, written or
 * charged, so a sender whose id LINE withholds still gets the welcome. It fires
 * on an unblock as well as a first follow, and both get the same message —
 * `follow.isUnblocked` tells them apart, but LINE does not guarantee its
 * accuracy.
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
