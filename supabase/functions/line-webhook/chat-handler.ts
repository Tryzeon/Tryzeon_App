import { SupabaseClient } from "jsr:@supabase/supabase-js@2";
import { getOrCreateUserId as defaultGetOrCreateUserId } from "../_shared/line-user.ts";
import {
  type ChatMessage,
  classifyCoreError,
  LIMITS,
  runChatAgent,
} from "../_shared/chat/index.ts";
import { makeLineAnswerRows } from "./chat-hydrate.ts";
import { renderAnswer } from "./chat-render.ts";
import { type ConversationStore, dehydrateMessages } from "./conversation.ts";
import { chatErrorMessage, type ChatErrorKind } from "./messages.ts";
import { LineApi } from "./line-api.ts";

export interface TextEvent {
  replyToken: string;
  sourceUserId: string;
  text: string;
}

export interface ChatHandlerDeps {
  admin: SupabaseClient;
  line: LineApi;
  /** Public R2 base the hydrator resolves product image keys against. */
  imagesBaseUrl: string;
  conversations: ConversationStore;
  getOrCreateUserId?: typeof defaultGetOrCreateUserId;
  runChat?: typeof runChatAgent;
}

/**
 * One outbound batch, on the reply token if it still holds and on a push if not.
 *
 * Any reply failure takes the fallback: an expired token and a LINE outage mean
 * the same thing here — the answer has not been delivered — and telling them
 * apart would only add a way to get it wrong.
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
 * Full lifecycle for one forwarded text message: resolve user -> show the
 * typing indicator -> run one chat turn -> send the answer.
 *
 * Unlike the try-on path there is no onboarding gate: chat needs no model
 * photo, so someone who just followed the OA can be answered on their first
 * message.
 *
 * A reply costs nothing against the messaging quota and a push costs one per
 * message, so every exit goes through `deliver`. The token holds for about a
 * minute and a turn is usually a few seconds — but `MAX_AGENT_STEPS` is 10, and
 * LINE says not to rely on the limit, so the fallback is what makes the tail
 * safe rather than lossy.
 *
 * The conversation is stored between messages (see `conversation.ts`), so the
 * turn runs on the transcript so far plus this message and the result is
 * written back. Nothing is written when the turn fails: a stored user message
 * with no answer is a question the next turn's model would read as ignored.
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
  // is exactly the wait the indicator exists to cover. Cosmetic, so a failure
  // here must not cost the caller their answer.
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
    const { blocks, messages } = await runChat(
      { admin: deps.admin },
      { userId, messages: transcript },
      { hydrate: makeLineAnswerRows(deps.imagesBaseUrl) },
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
 * Renders a core error as one of this channel's message kinds, from the same
 * `classifyCoreError` result the HTTP adapters use. A validation error is not
 * about anything the user typed just now — this message was already
 * length-checked above, so the *history* is the likelier culprit once a
 * transcript is being replayed every turn — but nothing here acts on that
 * beyond the wording: every kind is reported and then dropped, and the stored
 * conversation is left for its idle TTL to retire.
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
