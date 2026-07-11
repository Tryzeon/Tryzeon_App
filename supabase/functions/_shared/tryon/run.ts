import { QuotaManager } from "../quota.ts";
import {
  base64ToUint8Array,
  detectMimeType,
  mimeTypeToExtension,
} from "../image-utils.ts";
import { uploadTryonImageToR2 } from "../r2.ts";
import { USER_AVATARS_BUCKET, WARDROBE_IMAGES_BUCKET } from "../storage.ts";
import { generateTryonImage } from "./image.ts";
import { generateTryonVideo } from "./video.ts";
import { makeSourceResolver, resolveGarments } from "./sources.ts";
import { assertTryonParams } from "./validate.ts";
import {
  GenerationFailedError,
  QuotaExceededError,
  type TryonClients,
  type TryonParams,
  type TryonResult,
} from "./types.ts";

export interface RunTryonJobDeps {
  generate?: typeof generateTryonImage;
  generateVideo?: typeof generateTryonVideo;
  upload?: typeof uploadTryonImageToR2;
  now?: () => number;
}

/**
 * Single try-on entry point: validate -> quota -> resolve -> generate ->
 * (image: upload | video: animate + upload). Quota uses the privileged `admin`
 * client; source paths are read through `materials` (defaults to admin) so the
 * caller's RLS bounds which storage paths a request can fetch.
 */
export async function runTryonJob(
  clients: TryonClients,
  params: TryonParams,
  deps: RunTryonJobDeps = {},
): Promise<TryonResult> {
  assertTryonParams(params);

  const generate = deps.generate ?? generateTryonImage;
  const generateVideo = deps.generateVideo ?? generateTryonVideo;
  const upload = deps.upload ?? uploadTryonImageToR2;
  const now = deps.now ?? Date.now;

  const materials = clients.materials ?? clients.admin;

  const feature = params.mode === "video" ? "tryon_video" : "tryon";
  const quota = new QuotaManager(clients.admin, params.userId, feature);
  const { allowed, usage } = await quota.incrementQuota();
  if (!allowed) {
    throw new QuotaExceededError(usage);
  }

  try {
    const avatarResolver = makeSourceResolver(materials, USER_AVATARS_BUCKET);
    const garmentResolver = makeSourceResolver(materials, WARDROBE_IMAGES_BUCKET);
    const [avatarBase64, garmentGroups] = await Promise.all([
      avatarResolver(params.avatar),
      resolveGarments(params.garments, garmentResolver),
    ]);

    const generated = await generate(avatarBase64, garmentGroups, params.scenePrompt);
    if (!generated) {
      throw new GenerationFailedError("image generation returned null");
    }

    if (params.mode === "video") {
      const videoUrl = await generateVideo(
        generated,
        params.userId,
        params.transitionPrompt,
      );
      return { kind: "video", videoUrl, usage };
    }

    const cleanBase64 = generated.replace(/^data:image\/[a-z]+;base64,/, "");
    const mimeType = detectMimeType(cleanBase64);
    const extension = mimeTypeToExtension(mimeType);
    const bytes = base64ToUint8Array(cleanBase64);
    const fileName = `${params.userId}/tryon-${now()}.${extension}`;
    const imageUrl = await upload(bytes, fileName, mimeType);

    return { kind: "image", imageUrl, usage };
  } catch (err) {
    await quota.rollbackQuota();
    throw err;
  }
}
