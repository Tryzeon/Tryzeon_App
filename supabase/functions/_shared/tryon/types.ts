import type { DailyUsage, UsageCounter } from "../quota.ts";
import type { BodyMeasurements } from "../user-profile.ts";
import type { TaskPromptOptions } from "./prompt.ts";
import type { DbClient } from "../supabase.ts";

export type { UsageCounter };

/**
 * Server-side only: what a resolver produces after reading a row it checked
 * ownership on, so it is never decoded from untrusted input and needs no
 * runtime guard.
 */
export type ImageSource = { path: string } | { base64: string };

/**
 * The only way a caller can name an avatar: the stored photo is resolved
 * server-side from the user's profile, so a path is not part of the contract.
 */
export type AvatarOverride = { base64: string };

/**
 * Inline bytes only: a finished result lives in the R2 try-on bucket, which
 * `fetchImageAsBase64` does not route, so `{ path }` would be an option that
 * always fails.
 */
export type BaseImage = { base64: string };

/** Absent `sizeId` means "describe the garment, not its fit". */
export interface ProductRef {
  productId: string;
  sizeId?: string;
}

/**
 * A reference and not a path, so binding the read to its owner is the core's
 * job rather than every adapter's — see `resolveWardrobeGarment`.
 */
export interface WardrobeRef {
  wardrobeItemId: string;
}

/**
 * Bytes and never a path: the LINE adapter runs on the admin client, where a
 * forwarded path reads the whole wardrobe bucket with nothing checking whose
 * it was. Anything stored is reached by reference instead, which the core
 * resolves against the job's own user.
 */
export interface GarmentMaterial {
  images: { base64: string }[];
}

/**
 * Declares its own `images` rather than extending {@link GarmentMaterial}: a
 * caller sends inline bytes, a resolver produces a storage key, and sharing one
 * field would force the looser of the two on both.
 */
export interface ResolvedGarment {
  images: ImageSource[];
  detail?: string;
  fit?: string;
}

export type GarmentInput = ProductRef | WardrobeRef | GarmentMaterial;

export function isProductRef(garment: GarmentInput): garment is ProductRef {
  return "productId" in garment;
}

export function isWardrobeRef(garment: GarmentInput): garment is WardrobeRef {
  return "wardrobeItemId" in garment;
}

export type TryonMode = "image" | "video";

/**
 * Video goes through the same image pass, so this is not an image-mode-only
 * setting; only an animate job escapes it. Defaults to `standard`.
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
 * `usage` is the caller's whole counter row for the day — every feature's
 * count, `chat_count` included — because that is what the client syncs its
 * usage cache from after any request that charges quota.
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

/**
 * Takes no client: the quota RPCs are `SECURITY DEFINER` and granted to
 * `service_role` alone — `refund` especially, since a user able to call it has
 * unlimited quota — so charging cannot run on the client a job reads with.
 * Binding the service-role key into the factory (see `supabaseQuota`) keeps
 * that credential in the adapter and hands the core a capability instead.
 */
export type QuotaFactory = (
  userId: string,
  mode: TryonMode,
) => UsageCounter;

/**
 * Resolves to clean base64 image data (no data-URI prefix — stripping any
 * provider preamble is the implementation's job), or null when the model
 * returned no image.
 */
export type ImageGenerator = (
  avatarBase64: string,
  garmentGroups: string[][],
  opts?: ImageGenerationOptions,
) => Promise<string | null>;

/** `engine` names a model rather than text, so the prompt builder ignores it. */
export interface ImageGenerationOptions extends TaskPromptOptions {
  engine?: TryonEngine;
}

export type VideoGenerator = (
  tryonImageBase64: string,
  transitionPrompt?: string,
) => Promise<Uint8Array>;

export type ImageUploader = (
  bytes: Uint8Array,
  fileName: string,
  contentType: string,
) => Promise<string>;

export type VideoUploader = (
  bytes: Uint8Array,
  fileName: string,
) => Promise<string>;

/** A `null` body means "describe the garment, not its fit". */
export type ProductResolver = (
  client: DbClient,
  ref: ProductRef,
  body: BodyMeasurements | null,
) => Promise<ResolvedGarment>;

/**
 * Takes the owner as well as the id: a wardrobe read is only correct bound to
 * whose wardrobe it is, and the binding is written out rather than left to RLS
 * because the LINE adapter passes a client with no policy beneath it.
 */
export type WardrobeResolver = (
  client: DbClient,
  userId: string,
  wardrobeItemId: string,
) => Promise<ResolvedGarment>;

export type AvatarResolver = (
  client: DbClient,
  userId: string,
) => Promise<ImageSource>;

export type BodyResolver = (
  client: DbClient,
  userId: string,
) => Promise<BodyMeasurements | null>;
