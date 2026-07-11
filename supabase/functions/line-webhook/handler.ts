import { SupabaseClient } from "jsr:@supabase/supabase-js@2";
import { resolveSupabaseUser } from "../_shared/line-user.ts";
import {
  GenerationFailedError,
  QuotaExceededError,
  runTryonJob,
} from "../_shared/tryon-run.ts";
import { uint8ToBase64 } from "../_shared/image-utils.ts";
import { getAvatarPath as defaultGetAvatarPath } from "./profile.ts";
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
  resolveUser?: typeof resolveSupabaseUser;
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
  const resolveUser = deps.resolveUser ?? resolveSupabaseUser;
  const runJob = deps.runJob ?? runTryonJob;

  const userId = await resolveUser(deps.admin, { sub: event.sourceUserId });
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
    const { imageUrl } = await runJob(deps.admin, {
      userId,
      avatar: { path: avatarPath },
      garments: [[{ base64: garmentBase64 }]],
    });
    await deps.line.push(event.sourceUserId, [resultMessage(imageUrl)]);
  } catch (err) {
    const kind = err instanceof QuotaExceededError
      ? "quota"
      : err instanceof GenerationFailedError
      ? "generation"
      : "unknown";
    await deps.line.push(event.sourceUserId, [errorMessage(kind)]);
  }
}
