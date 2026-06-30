// supabase/functions/liff-tryon/tryon-core.ts
import { SupabaseClient } from "jsr:@supabase/supabase-js@2";
import { QuotaManager } from "../_shared/quota.ts";
import {
  base64ToUint8Array,
  detectMimeType,
  fetchImageAsBase64,
  mimeTypeToExtension,
} from "../_shared/image-utils.ts";
import { uploadTryonImageToR2 } from "../_shared/r2.ts";
import { generateTryonImage } from "./image-gen.ts";

export class QuotaExceededError extends Error {
  constructor(public usage: unknown) {
    super("quota exceeded");
  }
}
export class GenerationFailedError extends Error {}

export interface RunTryonDeps {
  generate?: typeof generateTryonImage;
  fetchImage?: typeof fetchImageAsBase64;
  upload?: typeof uploadTryonImageToR2;
}

export interface RunTryonResult {
  imageUrl: string;
  usage: unknown;
}

/**
 * LINE-side try-on orchestration. Mirrors the success path of
 * supabase/functions/tryon/index.ts but is driven by an explicit userId
 * (resolved from a LINE identity) and an admin client.
 */
export async function runTryon(
  admin: SupabaseClient,
  userId: string,
  avatarBase64: string,
  garmentKey: string,
  deps: RunTryonDeps = {},
): Promise<RunTryonResult> {
  const generate = deps.generate ?? generateTryonImage;
  const fetchImage = deps.fetchImage ?? fetchImageAsBase64;
  const upload = deps.upload ?? uploadTryonImageToR2;

  const quota = new QuotaManager(admin, userId, "tryon");
  const { allowed, usage } = await quota.incrementQuota();
  if (!allowed) {
    throw new QuotaExceededError(usage);
  }

  try {
    const garmentBase64 = await fetchImage(admin, garmentKey);
    const generated = await generate(avatarBase64, [[garmentBase64]], undefined);
    if (!generated) {
      throw new GenerationFailedError("image generation returned null");
    }

    const cleanBase64 = generated.replace(/^data:image\/[a-z]+;base64,/, "");
    const mimeType = detectMimeType(cleanBase64);
    const extension = mimeTypeToExtension(mimeType);
    const bytes = base64ToUint8Array(cleanBase64);
    const fileName = `${userId}/liff-${Date.now()}.${extension}`;
    const imageUrl = await upload(bytes, fileName, mimeType);

    return { imageUrl, usage };
  } catch (err) {
    await quota.rollbackQuota();
    throw err;
  }
}
