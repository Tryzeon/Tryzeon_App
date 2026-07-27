import { SupabaseClient } from "jsr:@supabase/supabase-js@2";
import { getOrCreateUserId as defaultGetOrCreateUserId } from "../_shared/line-user.ts";
import { classifyCoreError, LIMITS, runChatAgent } from "../_shared/chat/index.ts";
import { makeLineAnswerRows } from "./chat-hydrate.ts";
import { renderAnswer } from "./chat-render.ts";
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
 * The conversation is not stored, so each message is a turn of one. The core
 * takes a whole transcript and is handed a single-message one — nothing about
 * that is a special case for it.
 */
export async function handleTextMessage(
  deps: ChatHandlerDeps,
  event: TextEvent,
): Promise<void> {
  const getOrCreateUserId = deps.getOrCreateUserId ?? defaultGetOrCreateUserId;
  const runChat = deps.runChat ?? runChatAgent;

  // Checked before anything is charged, because this is the one core rule the
  // user can break themselves: LINE accepts a longer message than the core does.
  // Every other rejection would mean this adapter built its params wrong, which
  // is why `chatFailureKind` treats a validation error as a fault of ours.
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
  const userId = await getOrCreateUserId(deps.admin, { sub: event.sourceUserId });
  await loading;

  try {
    const { blocks } = await runChat(
      { admin: deps.admin },
      {
        userId,
        messages: [{ role: "user", content: [{ type: "text", text: event.text }] }],
      },
      { hydrate: makeLineAnswerRows(deps.imagesBaseUrl) },
    );
    await deps.line.push(event.sourceUserId, renderAnswer(blocks));
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
 * user-actionable here — the only user-supplied field was length-checked above,
 * so anything left means we sent something wrong — and is reported as a fault.
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
