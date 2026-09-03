import {
  base64ToUint8Array,
  detectMimeType,
  mimeTypeToExtension,
} from "../image-utils.ts";
import { uploadTryonImageToR2, uploadTryonVideoToR2 } from "../r2.ts";
import { USER_AVATARS_BUCKET, WARDROBE_IMAGES_BUCKET } from "../storage.ts";
import { resolveStoredAvatar } from "./avatar.ts";
import { resolveProductGarment } from "./catalog.ts";
import { resolveWardrobeGarment } from "./wardrobe.ts";
import { generateTryonImage, generateTryonVideo } from "./vertex.ts";
import { loadGarments, makeSourceLoader } from "./sources.ts";
import { validateTryonParams } from "./validate.ts";
import { GenerationFailedError } from "./errors.ts";
import { QuotaExceededError } from "../quota.ts";
import { getBodyMeasurements } from "../user-profile.ts";
import {
  isProductRef,
  isWardrobeRef,
  type AvatarResolver,
  type BodyResolver,
  type ImageGenerator,
  type ImageSource,
  type ImageUploader,
  type ProductResolver,
  type WardrobeResolver,
  type QuotaFactory,
  type ResolvedGarment,
  type TryonMode,
  type TryonParams,
  type TryonResultFor,
  type VideoGenerator,
  type VideoUploader,
} from "./types.ts";
import type { DbClient } from "../supabase.ts";

type TryonSource =
  | { kind: "animate"; base64: string }
  | { kind: "generate"; avatar: ImageSource };

export interface RunTryonJobDeps {
  /**
   * The one required port: its implementation needs a service-role client, and
   * which one is the adapter's to say. `supabaseQuota(adminClient)` builds it.
   */
  quota: QuotaFactory;
  generate?: ImageGenerator;
  generateVideo?: VideoGenerator;
  upload?: ImageUploader;
  uploadVideo?: VideoUploader;
  resolveProduct?: ProductResolver;
  resolveWardrobe?: WardrobeResolver;
  resolveAvatar?: AvatarResolver;
  resolveBody?: BodyResolver;
  now?: () => number;
}

/**
 * Single try-on entry point: validate -> resolve avatar -> quota -> resolve
 * garments -> load -> generate -> persist.
 *
 * One client, and it is the caller's own: an adapter with a session (the app)
 * has RLS bounding what a request can reach, while an adapter without one
 * (LINE, LIFF) passes its admin client and RLS bounds nothing — which is why
 * the resolvers check ownership and namespace themselves rather than leaning
 * on it.
 */
export async function runTryonJob<M extends TryonMode>(
  client: DbClient,
  params: TryonParams & { mode: M },
  deps: RunTryonJobDeps,
): Promise<TryonResultFor<M>> {
  // Everything below runs on `job`, never on the raw `params`: the guard is
  // also the normalizer, so the job cannot read a source the guard did not see.
  const job = validateTryonParams(params);

  const generate = deps.generate ?? generateTryonImage;
  const generateVideo = deps.generateVideo ?? generateTryonVideo;
  const upload = deps.upload ?? uploadTryonImageToR2;
  const uploadVideo = deps.uploadVideo ?? uploadTryonVideoToR2;
  const resolveProduct = deps.resolveProduct ?? resolveProductGarment;
  const resolveWardrobe = deps.resolveWardrobe ?? resolveWardrobeGarment;
  const resolveBody = deps.resolveBody ?? getBodyMeasurements;
  const now = deps.now ?? Date.now;

  const resolveAvatar = deps.resolveAvatar ?? resolveStoredAvatar;

  // An animate job resolves no avatar: looking one up would fail a user with no
  // stored photo for a job that never needed it. Stays above the quota charge
  // either way, so a missing avatar is still reported before anyone is billed.
  const source: TryonSource = job.baseImage
    ? { kind: "animate", base64: job.baseImage.base64 }
    : {
      kind: "generate",
      avatar: job.avatar ?? await resolveAvatar(client, job.userId),
    };

  const quota = deps.quota(job.userId, job.mode);
  const { allowed, usage } = await quota.charge();
  if (!allowed) {
    throw new QuotaExceededError(usage);
  }

  try {
    let generated: string | null;
    if (source.kind === "animate") {
      generated = source.base64;
    } else {
      const needsBody = job.garments.some(
        (g) => isProductRef(g) && g.sizeId !== undefined,
      );
      // A profile read that fails must not fail a job that would have succeeded
      // without a sizeId.
      const body = needsBody
        ? await resolveBody(client, job.userId).catch((err) => {
          console.warn("body measurements lookup failed; skipping fit:", err);
          return null;
        })
        : null;

      // Stage 1: resolve product and wardrobe refs to concrete garment material.
      // The resolvers are the gatekeepers — a client can only reach a real
      // product's image or its own wardrobe item, whether or not RLS sits
      // beneath `client`.
      const materialGarments: ResolvedGarment[] = await Promise.all(
        job.garments.map((g) =>
          isProductRef(g)
            ? resolveProduct(client, g, body)
            : isWardrobeRef(g)
            ? resolveWardrobe(client, job.userId, g.wardrobeItemId)
            : g
        ),
      );

      // Stage 2: load avatar + garment images as base64.
      const loadAvatar = makeSourceLoader(client, USER_AVATARS_BUCKET);
      const loadGarment = makeSourceLoader(client, WARDROBE_IMAGES_BUCKET);
      const [avatarBase64, garmentGroups] = await Promise.all([
        loadAvatar(source.avatar),
        loadGarments(materialGarments, loadGarment),
      ]);

      const garmentDetails = materialGarments.map((g) => g.detail);
      const garmentFits = materialGarments.map((g) => g.fit);

      generated = await generate(avatarBase64, garmentGroups, {
        engine: job.engine,
        scenePrompt: job.scenePrompt,
        stylingPrompt: job.stylingPrompt,
        garmentDetails,
        garmentFits,
      });
    }

    if (!generated) {
      throw new GenerationFailedError("image generation returned null");
    }

    // Stage 3: persist. The two casts are the single point where the
    // mode -> result-variant correspondence is asserted.
    if (job.mode === "video") {
      const bytes = await generateVideo(generated, job.transitionPrompt);
      const videoUrl = await uploadVideo(
        bytes,
        assetKey(job.userId, now(), "mp4"),
      );
      return { kind: "video", videoUrl, usage } as TryonResultFor<M>;
    }

    const mimeType = detectMimeType(generated);
    const imageUrl = await upload(
      base64ToUint8Array(generated),
      assetKey(job.userId, now(), mimeTypeToExtension(mimeType)),
      mimeType,
    );
    return { kind: "image", imageUrl, usage } as TryonResultFor<M>;
  } catch (err) {
    // Refund is best-effort: a failure here must not replace the error that
    // actually caused the job to fail, or callers would report the wrong thing.
    try {
      await quota.refund();
    } catch (refundErr) {
      console.error("try-on quota refund failed:", refundErr);
    }
    throw err;
  }
}

function assetKey(
  userId: string,
  timestamp: number,
  extension: string,
): string {
  return `${userId}/tryon-${timestamp}.${extension}`;
}
