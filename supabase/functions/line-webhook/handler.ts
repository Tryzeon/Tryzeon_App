import { SupabaseClient } from "jsr:@supabase/supabase-js@2";
import { getOrCreateUserId as defaultGetOrCreateUserId } from "../_shared/line-user.ts";
import { classifyTryonError, runTryonJob } from "../_shared/tryon/index.ts";
import { uint8ToBase64 } from "../_shared/image-utils.ts";
import { getAvatarPath as defaultGetAvatarPath } from "../_shared/user-profile.ts";
import {
  errorMessage,
  onboardingMessage,
  processingMessage,
  resultMessage,
} from "./messages.ts";
import { LineApi } from "./line-api.ts";

export interface ImageEvent {
  replyToken: string;
  sourceUserId: string;
  messageId: string;
}

export interface HandlerDeps {
  admin: SupabaseClient;
  line: LineApi;
  liffOnboardUrl: string;
  getAvatarPath?: typeof defaultGetAvatarPath;
  getOrCreateUserId?: typeof defaultGetOrCreateUserId;
  runJob?: typeof runTryonJob;
}

/**
 * Full lifecycle for one forwarded image: resolve user -> onboard if no model
 * photo -> otherwise reply "processing" and (in the caller's background task)
 * download the garment, run try-on with the stored avatar, and push the result.
 */
export async function handleImageMessage(
  deps: HandlerDeps,
  event: ImageEvent,
): Promise<void> {
  const getAvatarPath = deps.getAvatarPath ?? defaultGetAvatarPath;
  const getOrCreateUserId = deps.getOrCreateUserId ?? defaultGetOrCreateUserId;
  const runJob = deps.runJob ?? runTryonJob;

  const userId = await getOrCreateUserId(deps.admin, {
    sub: event.sourceUserId,
  });
  const avatarPath = await getAvatarPath(deps.admin, userId);

  if (!avatarPath) {
    await deps.line.reply(event.replyToken, [onboardingMessage(deps.liffOnboardUrl)]);
    return;
  }

  await deps.line.reply(event.replyToken, [processingMessage()]);

  let bytes: Uint8Array;
  try {
    bytes = await deps.line.getContent(event.messageId);
  } catch {
    await deps.line.push(event.sourceUserId, [errorMessage("download")]);
    return;
  }

  try {
    const garmentBase64 = uint8ToBase64(bytes);
    // `materials: admin` is safe here and stated explicitly: the avatar path is
    // server-derived (read from the user's own profile) and the garment arrives
    // as base64 — this adapter never forwards a client-supplied path.
    const result = await runJob({ admin: deps.admin, materials: deps.admin }, {
      userId,
      avatar: { path: avatarPath },
      garments: [{ images: [{ base64: garmentBase64 }] }],
      mode: "image",
    });
    await deps.line.push(event.sourceUserId, [resultMessage(result.imageUrl)]);
  } catch (err) {
    const kind = tryonFailureKind(err);
    // "unknown" means a server-side fault (bad params, RLS, storage) rather
    // than a user error — log it so it leaves a trace beyond the pushed message.
    if (kind === "unknown") {
      console.error("line-webhook try-on failed:", err);
    }
    await deps.line.push(event.sourceUserId, [errorMessage(kind)]);
  }
}

/**
 * Renders a core error as one of this channel's message kinds, from the same
 * `classifyTryonError` result the HTTP adapters use. A validation error is not
 * user-actionable here — this adapter builds its own params, so it means we
 * sent something wrong — and is reported as an unknown fault.
 */
function tryonFailureKind(err: unknown): "quota" | "generation" | "unknown" {
  const info = classifyTryonError(err);
  if (info === null) return "unknown";
  switch (info.kind) {
    case "quota":
      return "quota";
    case "generation":
      return "generation";
    case "validation":
      return "unknown";
  }
}
