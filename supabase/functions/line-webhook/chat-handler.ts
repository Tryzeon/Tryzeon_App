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
 * Full lifecycle for one forwarded text message: resolve user -> show the
 * typing indicator -> run one chat turn -> push the answer.
 *
 * Unlike the try-on path there is no onboarding gate: chat needs no model
 * photo, so someone who just followed the OA can be answered on their first
 * message.
 *
 * Every outbound message is a push rather than a reply. The turn takes as long
 * as the agent's tool loop does, which is far past the point where a reply token
 * can be relied on; the typing indicator covers the wait instead, and costs
 * nothing against the messaging quota.
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
    await deps.line.push(event.sourceUserId, [chatErrorMessage("too_long")]);
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
    getOrCreateUserId(deps.admin, { sub: event.sourceUserId }),
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

    await deps.line.push(event.sourceUserId, renderAnswer(blocks));

    await deps.conversations.save(
      event.sourceUserId,
      dehydrateMessages([...transcript, ...messages]),
    );
  } catch (err) {
    const kind = chatFailureKind(err);
    if (kind === "unknown") {
      console.error("line-webhook chat failed:", err);
    }
    await deps.line.push(event.sourceUserId, [chatErrorMessage(kind)]);
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
    case "validation":
      return "unknown";
  }
}
