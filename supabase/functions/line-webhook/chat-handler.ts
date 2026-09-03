import { getOrCreateUserId as defaultGetOrCreateUserId } from "../_shared/line-user.ts";
import {
  type ChatMessage,
  classifyCoreError,
  LIMITS,
  runChatAgent,
  supabaseChatQuota,
} from "../_shared/chat/index.ts";
import { makeLineAnswerRows } from "./chat-hydrate.ts";
import { renderAnswer } from "./chat-render.ts";
import { type ConversationStore, dehydrateMessages } from "./conversation.ts";
import { chatErrorMessage, type ChatErrorKind } from "./messages.ts";
import { LineApi } from "./line-api.ts";
import type { DbClient } from "../_shared/supabase.ts";

export interface TextEvent {
  replyToken: string;
  sourceUserId: string;
  text: string;
}

export interface ChatHandlerDeps {
  admin: DbClient;
  line: LineApi;
  imagesBaseUrl: string;
  conversations: ConversationStore;
  getOrCreateUserId?: typeof defaultGetOrCreateUserId;
  runChat?: typeof runChatAgent;
}

/**
 * Any reply failure takes the push fallback: an expired token and a LINE outage
 * mean the same thing here — the answer has not been delivered.
 */
async function deliver(
  deps: ChatHandlerDeps,
  event: TextEvent,
  messages: object[],
): Promise<void> {
  try {
    await deps.line.reply(event.replyToken, messages);
  } catch (err) {
    console.warn("line-webhook reply failed, pushing instead:", err);
    await deps.line.push(event.sourceUserId, messages);
  }
}

/**
 * A reply costs nothing against the messaging quota and a push costs one per
 * message, so every exit goes through `deliver`. The token holds for about a
 * minute and a turn is usually a few seconds — but `MAX_AGENT_STEPS` is 10, and
 * LINE says not to rely on the limit, so the fallback is what makes the tail
 * safe rather than lossy.
 *
 * Nothing is stored when the turn fails: a stored user message with no answer is
 * a question the next turn's model would read as ignored.
 */
export async function handleTextMessage(
  deps: ChatHandlerDeps,
  event: TextEvent,
): Promise<void> {
  const getOrCreateUserId = deps.getOrCreateUserId ?? defaultGetOrCreateUserId;
  const runChat = deps.runChat ?? runChatAgent;

  if (event.text.length > LIMITS.MAX_TEXT_LENGTH) {
    await deliver(deps, event, [chatErrorMessage("too_long")]);
    return;
  }

  // Started before the user is resolved, since it needs only the LINE id: for a
  // first-time sender that resolution creates an auth user, and the wait it adds
  // is exactly the wait the indicator exists to cover.
  const loading = deps.line.showLoading(event.sourceUserId).catch((err) => {
    console.warn("line-webhook loading indicator failed:", err);
  });
  const [prior, userId] = await Promise.all([
    deps.conversations.load(event.sourceUserId),
    getOrCreateUserId(
      deps.admin,
      { sub: event.sourceUserId },
      () => deps.line.getDisplayName(event.sourceUserId),
    ),
  ]);
  await loading;

  const userMessage: ChatMessage = {
    role: "user",
    content: [{ type: "text", text: event.text }],
  };

  const transcript = [...prior, userMessage];

  try {
    // A LINE event carries no Supabase session, so there is no user-scoped
    // client to bound these reads; every query the core runs here is
    // server-composed and scoped by `userId`.
    const { blocks, messages } = await runChat(
      deps.admin,
      { userId, messages: transcript },
      {
        quota: supabaseChatQuota(deps.admin),
        hydrate: makeLineAnswerRows(deps.imagesBaseUrl),
      },
    );

    await deliver(deps, event, renderAnswer(blocks));

    await deps.conversations.save(
      event.sourceUserId,
      dehydrateMessages([...transcript, ...messages]),
    );
  } catch (err) {
    const kind = chatFailureKind(err);
    if (kind === "unknown") {
      console.error("line-webhook chat failed:", err);
    }
    await deliver(deps, event, [chatErrorMessage(kind)]);
  }
}

/**
 * A validation error is not about what the user just typed — that was
 * length-checked above, so the replayed history is the likelier culprit — but
 * nothing acts on the distinction beyond the wording.
 */
function chatFailureKind(err: unknown): ChatErrorKind {
  const info = classifyCoreError(err);
  if (info === null) return "unknown";
  switch (info.kind) {
    case "quota":
      return "quota";
    case "busy":
      return "unknown";
    case "validation":
      return "unknown";
  }
}
