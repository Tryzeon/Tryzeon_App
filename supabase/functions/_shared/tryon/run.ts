import {
  base64ToUint8Array,
  detectMimeType,
  mimeTypeToExtension,
} from "../image-utils.ts";
import { uploadTryonImageToR2, uploadTryonVideoToR2 } from "../r2.ts";
import { USER_AVATARS_BUCKET, WARDROBE_IMAGES_BUCKET } from "../storage.ts";
import { resolveProductGarment } from "./catalog.ts";
import { supabaseQuota } from "./quota.ts";
import { generateTryonImage, generateTryonVideo } from "./vertex.ts";
import { loadGarments, makeSourceLoader } from "./sources.ts";
import { validateTryonParams } from "./validate.ts";
import { GenerationFailedError } from "./errors.ts";
import { QuotaExceededError } from "../quota.ts";
import {
  isGarmentRef,
  type ImageGenerator,
  type ImageUploader,
  type ProductResolver,
  type QuotaFactory,
  type ResolvedGarment,
  type TryonClients,
  type TryonMode,
  type TryonParams,
  type TryonResultFor,
  type VideoGenerator,
  type VideoUploader,
} from "./types.ts";

export interface RunTryonJobDeps {
  generate?: ImageGenerator;
  generateVideo?: VideoGenerator;
  upload?: ImageUploader;
  uploadVideo?: VideoUploader;
  resolveProduct?: ProductResolver;
  quota?: QuotaFactory;
  now?: () => number;
}

/**
 * Single try-on entry point: validate -> quota -> resolve -> load -> generate
 * -> persist. Both modes end in a core-owned upload, so the result of a job is
 * always a URL the caller can hand straight to its client. Quota uses the
 * privileged `admin` client; source paths are read through `materials` so the
 * caller's RLS bounds which storage objects a request can fetch.
 *
 * The result type follows the mode: callers that hard-code a mode get exactly
 * that variant back, so narrowing the union is the compiler's job rather than a
 * runtime check at each call site.
 */
export async function runTryonJob<M extends TryonMode>(
  clients: TryonClients,
  params: TryonParams & { mode: M },
  deps: RunTryonJobDeps = {},
): Promise<TryonResultFor<M>> {
  // Everything below runs on `job`, never on the raw `params`: the guard is
  // also the normalizer, so the job cannot read a source the guard did not see.
  const job = validateTryonParams(params);

  const generate = deps.generate ?? generateTryonImage;
  const generateVideo = deps.generateVideo ?? generateTryonVideo;
  const upload = deps.upload ?? uploadTryonImageToR2;
  const uploadVideo = deps.uploadVideo ?? uploadTryonVideoToR2;
  const resolveProduct = deps.resolveProduct ?? resolveProductGarment;
  const openQuota = deps.quota ?? supabaseQuota;
  const now = deps.now ?? Date.now;

  const quota = openQuota(clients.admin, job.userId, job.mode);
  const { allowed, usage } = await quota.charge();
  if (!allowed) {
    throw new QuotaExceededError(usage);
  }

  try {
    // Stage 1: resolve product refs to concrete garment material. Uses the
    // privileged admin client — resolveProductGarment is the gatekeeper, so a
    // client can only reach a real product's image, never an arbitrary object.
    // User-supplied material passes through untouched, which is also why this
    // is the only stage that can attach a `detail`: the description reaching
    // the model is built here or not at all.
    const materialGarments: ResolvedGarment[] = await Promise.all(
      job.garments.map((g) =>
        isGarmentRef(g) ? resolveProduct(clients.admin, g.productId) : g
      ),
    );

    // Stage 2: load avatar + garment images as base64. Paths are read through
    // `materials` so the caller's RLS bounds which objects it can fetch.
    const loadAvatar = makeSourceLoader(clients.materials, USER_AVATARS_BUCKET);
    const loadGarment = makeSourceLoader(
      clients.materials,
      WARDROBE_IMAGES_BUCKET,
    );
    const [avatarBase64, garmentGroups] = await Promise.all([
      loadAvatar(job.avatar),
      loadGarments(materialGarments, loadGarment),
    ]);

    const garmentDetails = materialGarments.map((g) => g.detail);

    const generated = await generate(
      avatarBase64,
      garmentGroups,
      job.scenePrompt,
      garmentDetails,
    );

    if (!generated) {
      throw new GenerationFailedError("image generation returned null");
    }

    // Stage 3: persist. Generators produce bytes; only this stage names keys
    // and uploads, so image and video obey one policy and one injectable clock.
    // The two casts are the single point where the mode -> result-variant
    // correspondence is asserted; every caller inherits it for free.
    if (job.mode === "video") {
      const bytes = await generateVideo(generated, job.transitionPrompt);
      const videoUrl = await uploadVideo(
        bytes,
        assetKey(job.userId, now(), "mp4"),
      );
      return { kind: "video", videoUrl, usage } as TryonResultFor<M>;
    }

    // `generated` is clean base64 by the ImageGenerator contract; stripping a
    // provider's data-URI preamble belongs to the provider adapter, not here.
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

/** User-scoped storage key for a generated asset, shared by both modes. */
function assetKey(userId: string, timestamp: number, extension: string): string {
  return `${userId}/tryon-${timestamp}.${extension}`;
}
