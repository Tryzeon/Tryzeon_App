import { SupabaseClient } from "jsr:@supabase/supabase-js@2";
import { QuotaManager } from "./quota.ts";
import {
  base64ToUint8Array,
  detectMimeType,
  mimeTypeToExtension,
} from "./image-utils.ts";
import { uploadTryonImageToR2 } from "./r2.ts";
import { generateTryonImage } from "./tryon-generate.ts";
import { makeSourceResolver, resolveGarments, type ImageSource } from "./tryon-sources.ts";
import { USER_AVATARS_BUCKET, WARDROBE_IMAGES_BUCKET } from "./storage.ts";

export class QuotaExceededError extends Error {
  constructor(public usage: unknown) {
    super("quota exceeded");
  }
}
export class GenerationFailedError extends Error {}

export interface RunTryonJobParams {
  userId: string;
  avatar: ImageSource;
  garments: ImageSource[][];
  scenePrompt?: string;
}

export interface RunTryonJobDeps {
  generate?: typeof generateTryonImage;
  upload?: typeof uploadTryonImageToR2;
  now?: () => number;
}

export interface RunTryonJobResult {
  imageUrl: string;
  usage: unknown;
}

/**
 * Unified image try-on orchestration driven by an explicit userId and a
 * client (admin for LINE/LIFF, user-scoped for app). Avatar and garments are
 * arbitrary ImageSources ({path} for stored images, {base64} for inline).
 */
export async function runTryonJob(
  client: SupabaseClient,
  params: RunTryonJobParams,
  deps: RunTryonJobDeps = {},
): Promise<RunTryonJobResult> {
  const generate = deps.generate ?? generateTryonImage;
  const upload = deps.upload ?? uploadTryonImageToR2;
  const now = deps.now ?? Date.now;

  const quota = new QuotaManager(client, params.userId, "tryon");
  const { allowed, usage } = await quota.incrementQuota();
  if (!allowed) {
    throw new QuotaExceededError(usage);
  }

  try {
    const avatarResolver = makeSourceResolver(client, USER_AVATARS_BUCKET);
    const garmentResolver = makeSourceResolver(client, WARDROBE_IMAGES_BUCKET);
    const [avatarBase64, garmentGroups] = await Promise.all([
      avatarResolver(params.avatar),
      resolveGarments(params.garments.map((images) => ({ images })), garmentResolver),
    ]);

    const generated = await generate(avatarBase64, garmentGroups, params.scenePrompt);
    if (!generated) {
      throw new GenerationFailedError("image generation returned null");
    }

    const cleanBase64 = generated.replace(/^data:image\/[a-z]+;base64,/, "");
    const mimeType = detectMimeType(cleanBase64);
    const extension = mimeTypeToExtension(mimeType);
    const bytes = base64ToUint8Array(cleanBase64);
    const fileName = `${params.userId}/tryon-${now()}.${extension}`;
    const imageUrl = await upload(bytes, fileName, mimeType);

    return { imageUrl, usage };
  } catch (err) {
    await quota.rollbackQuota();
    throw err;
  }
}
