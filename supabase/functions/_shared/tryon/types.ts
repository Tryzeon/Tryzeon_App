import type { DailyUsage, UsageCounter } from "../quota.ts";
import type { BodyMeasurements } from "../user-profile.ts";
import type { TaskPromptOptions } from "./prompt.ts";
import type { DbClient } from "../supabase.ts";

export type { UsageCounter };

/**
 * An image is addressed EITHER by storage key OR by inline bytes. A union
 * rather than two optional fields, so the empty `{}` case cannot be
 * constructed and loaders narrow with `in` instead of re-checking for a usable
 * key.
 *
 * Server-side only: no caller can name one. It is what a resolver produces
 * after reading a row it checked ownership on, so it is never decoded from
 * untrusted input and needs no runtime guard.
 */
export type ImageSource = { path: string } | { base64: string };

/**
 * An avatar supplied inline by the caller. The only way to name an avatar:
 * the stored photo is resolved server-side from the user's profile, so a path
 * is not part of the contract.
 */
export type AvatarOverride = { base64: string };

/**
 * Inline bytes only: a finished result lives in the R2 try-on bucket, which
 * `fetchImageAsBase64` does not route, so `{ path }` would be an option that
 * always fails.
 */
export type BaseImage = { base64: string };

/**
 * Try-on a catalog product by reference; the core resolves it to material.
 *
 * `sizeId` names which published size is being worn. Optional because most
 * callers have no size to name: the LIFF page and the LINE chat flow have no
 * fit calculation of their own, and a shopper with no recorded measurements has
 * no recommended size. Absent means "describe the garment, not its fit".
 */
export interface ProductRef {
  productId: string;
  sizeId?: string;
}

/**
 * Try-on an item from the sender's own wardrobe. A reference and not a path,
 * so that binding the read to its owner is the core's job rather than every
 * adapter's — see `resolveWardrobeGarment`.
 */
export interface WardrobeRef {
  wardrobeItemId: string;
}

/**
 * A garment described directly by the caller, as inline bytes.
 *
 * Bytes and never a path, for the reason an avatar override is bytes only: the
 * type cannot ask whether the caller may read that wardrobe-bucket object. The
 * app and LIFF hold a session, so RLS would bound them — but the LINE adapter
 * runs on the admin client, where a forwarded path reads the whole bucket with
 * nothing checking whose it was. Anything stored is reached by reference
 * instead ({@link ProductRef}, {@link WardrobeRef}), which the core resolves
 * against the job's own user.
 */
export interface GarmentMaterial {
  images: { base64: string }[];
}

/**
 * Garment material as the model will finally see it: the sources, plus the
 * description built for a catalog product.
 *
 * Declares its own `images` rather than extending {@link GarmentMaterial}: a
 * caller may send inline bytes, while a resolver usually produces a storage
 * key, since resolving a reference is how a path becomes trusted. Sharing one
 * field would force the looser of the two on both.
 *
 * `detail` likewise is never written by a caller — it is composed server-side
 * from rows the server read (`resolveProductGarment`,
 * `resolveWardrobeGarment`), after validation.
 */
export interface ResolvedGarment {
  images: ImageSource[];
  detail?: string;
  fit?: string;
}

/**
 * A garment is a product reference, one of the user's own wardrobe items, or
 * material they supplied directly. Both reference kinds are resolved
 * server-side; only the third carries bytes or paths from a caller.
 */
export type GarmentInput = ProductRef | WardrobeRef | GarmentMaterial;

export function isProductRef(garment: GarmentInput): garment is ProductRef {
  return "productId" in garment;
}

export function isWardrobeRef(garment: GarmentInput): garment is WardrobeRef {
  return "wardrobeItemId" in garment;
}

export type TryonMode = "image" | "video";

/**
 * Which image model a job runs on. Video goes through the same image pass, so
 * this is not an image-mode-only setting; only an animate job escapes it, and
 * that job runs no image pass at all.
 *
 * A caller that names none gets `standard`, which is what every adapter without
 * a picker (LINE, LIFF) sends.
 */
export type TryonEngine = "standard" | "advanced";

export interface TryonParams {
  userId: string;
  avatar?: AvatarOverride;
  garments: GarmentInput[];
  mode: TryonMode;
  engine?: TryonEngine;
  scenePrompt?: string;
  stylingPrompt?: string;
  transitionPrompt?: string;
  /** Only valid with `mode: "video"`. */
  baseImage?: BaseImage;
}

/*
 * Results carry `DailyUsage`, not a try-on-shaped subset: a job hands back the
 * caller's whole counter row for the day — every feature's count, `chat_count`
 * included — because that is what the client syncs its usage cache from after
 * any request that charges quota. The row belongs to the counter, so
 * `_shared/quota.ts` declares it and chat publishes the same one.
 */

export interface TryonImageResult {
  kind: "image";
  imageUrl: string;
  usage: DailyUsage | null;
}

export interface TryonVideoResult {
  kind: "video";
  videoUrl: string;
  usage: DailyUsage | null;
}

export type TryonResult = TryonImageResult | TryonVideoResult;

/**
 * The result a given mode produces. A caller that hard-codes `mode: "image"`
 * gets `TryonImageResult` back and never has to check `kind` at runtime; a
 * caller whose mode is dynamic (the app) still gets the full union.
 */
export type TryonResultFor<M extends TryonMode> = M extends "image"
  ? TryonImageResult
  : TryonVideoResult;

export const LIMITS = {
  MAX_GARMENTS: 3,
  MAX_IMAGES_PER_GARMENT: 3,
  MAX_GARMENT_DETAIL_LENGTH: 500,
  MAX_GARMENT_FIT_LENGTH: 600,
  MAX_PROMPT_LENGTH: 1000,
  MAX_BASE64_LENGTH: 8 * 1024 * 1024,
} as const;

/*
 * Ports the core depends on. `run.ts` is written against these signatures and
 * wires the Vertex AI / R2 implementations as its defaults, so swapping a
 * provider (or a test double) is a substitution rather than an edit to the
 * orchestrator.
 */

/**
 * Opens the quota counter for one user + mode.
 *
 * Takes no client, and this is the one place that fact is explained. The quota
 * RPCs are `SECURITY DEFINER` and granted to `service_role` alone — `refund`
 * especially, since a user able to call it has unlimited quota — so charging
 * cannot run on the client a job reads with. Binding the service-role key into
 * the factory (see `supabaseQuota`) keeps that credential in the adapter and
 * hands the core a capability instead. Not a wall — `getAdminClient()` is one
 * import away under `_shared/` — but it makes the privileged step visible
 * rather than ambient.
 *
 * Takes the mode rather than a feature name so the backend's vocabulary
 * (`tryon` vs `tryon_video`) stays on the implementation side of the port. The
 * port it returns belongs to `_shared/quota.ts` — the charge/refund contract is
 * the counter's, not try-on's, and chat opens the same one.
 */
export type QuotaFactory = (
  userId: string,
  mode: TryonMode,
) => UsageCounter;

/**
 * Generates a try-on image; resolves to clean base64 image data (no data-URI
 * prefix — stripping any provider preamble is the implementation's job), or
 * null when the model returned no image.
 *
 * The prompt inputs are grouped into one options object rather than left as
 * positional parameters: `garmentDetails` and `garmentFits` are both
 * `(string | undefined)[]`, so two positionals of the same shape could be
 * transposed and still type-check — the wearer's body measurements under the
 * garment's appearance notes, or vice versa.
 *
 * The shape is `TaskPromptOptions` itself, not a copy: every field being
 * optional, a copy would stay structurally compatible after one side renamed a
 * field, silently dropping that input on its way to the prompt.
 */
export type ImageGenerator = (
  avatarBase64: string,
  garmentGroups: string[][],
  opts?: ImageGenerationOptions,
) => Promise<string | null>;

/**
 * Everything the prompt builder reads, plus the engine, which it does not: the
 * engine names a model rather than shaping the text. It extends
 * `TaskPromptOptions` instead of restating it so the shared-declaration
 * argument above still holds — a renamed prompt field is a compile error here
 * too — while keeping the model choice out of the prompt builder's signature.
 */
export interface ImageGenerationOptions extends TaskPromptOptions {
  engine?: TryonEngine;
}

/** Animates a generated try-on image; resolves to raw video bytes. */
export type VideoGenerator = (
  tryonImageBase64: string,
  transitionPrompt?: string,
) => Promise<Uint8Array>;

/** Persists a generated image and resolves to its retrievable URL. */
export type ImageUploader = (
  bytes: Uint8Array,
  fileName: string,
  contentType: string,
) => Promise<string>;

/** Persists a generated video and resolves to its retrievable URL. */
export type VideoUploader = (
  bytes: Uint8Array,
  fileName: string,
) => Promise<string>;

/**
 * Resolves a catalog product reference to trusted garment material. Takes the
 * whole ref rather than just an id, because the reference now also names which
 * size is worn, and the wearer's measurements, because describing that size's
 * fit needs a body to compare against. `null` body means "describe the garment,
 * not its fit".
 */
export type ProductResolver = (
  client: DbClient,
  ref: ProductRef,
  body: BodyMeasurements | null,
) => Promise<ResolvedGarment>;

/**
 * Resolves a wardrobe item reference to trusted garment material. Takes the
 * owner as well as the id: unlike the catalog, which is public, a wardrobe read
 * is only correct when it is bound to whose wardrobe it is — and the binding is
 * written out here rather than left to RLS, because the LINE adapter passes a
 * client with no policy beneath it.
 */
export type WardrobeResolver = (
  client: DbClient,
  userId: string,
  wardrobeItemId: string,
) => Promise<ResolvedGarment>;

/** Resolves the user's stored model photo into a loadable source. */
export type AvatarResolver = (
  client: DbClient,
  userId: string,
) => Promise<ImageSource>;

/** Resolves the wearer's recorded body dimensions, or null when they have none. */
export type BodyResolver = (
  client: DbClient,
  userId: string,
) => Promise<BodyMeasurements | null>;
