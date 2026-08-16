import { SupabaseClient } from "jsr:@supabase/supabase-js@2";
import type { DailyUsage, UsageCounter } from "../quota.ts";
import type { BodyMeasurements } from "../user-profile.ts";
import type { TaskPromptOptions } from "./prompt.ts";

export type { UsageCounter };

/**
 * An image is addressed EITHER by storage key OR by inline bytes. A union
 * rather than two optional fields, so the empty `{}` case cannot be
 * constructed and loaders narrow with `in` instead of re-checking for a usable
 * key. (TypeScript still admits an object literal carrying both keys — excess
 * property checks accept any key present in some union member — so
 * `requireImageSource` remains the runtime guard for unknown input.)
 */
export type ImageSource = { path: string } | { base64: string };

/**
 * An avatar supplied inline by the caller. The only way to name an avatar:
 * the stored photo is resolved server-side from the user's profile, so a path
 * is not part of the contract.
 */
export type AvatarOverride = { base64: string };

/**
 * Try-on a catalog product by reference; the core resolves it to material.
 *
 * `sizeId` names which published size is being worn. Optional because most
 * callers have no size to name: the LIFF page and the LINE chat flow have no
 * fit calculation of their own, and a shopper with no recorded measurements has
 * no recommended size. Absent means "describe the garment, not its fit".
 */
export interface GarmentRef {
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

/** A garment described directly by the user's own image sources. */
export interface GarmentMaterial {
  images: ImageSource[];
}

/**
 * Garment material as the model will finally see it: the sources, plus the
 * description built for a catalog product.
 *
 * `detail` lives here and not on `GarmentMaterial` because no caller writes it
 * directly: it is always composed server-side from rows the server itself
 * read (`resolveProductGarment`, `resolveWardrobeGarment`), after validation.
 */
export interface ResolvedGarment extends GarmentMaterial {
  detail?: string;
  fit?: string;
}

/**
 * A garment is a product reference, one of the user's own wardrobe items, or
 * material they supplied directly. Both reference kinds are resolved
 * server-side; only the third carries bytes or paths from a caller.
 */
export type GarmentInput = GarmentRef | WardrobeRef | GarmentMaterial;

/** True when a garment names a catalog product. */
export function isProductRef(garment: GarmentInput): garment is GarmentRef {
  return "productId" in garment;
}

/** True when a garment names one of the user's own wardrobe items. */
export function isWardrobeRef(garment: GarmentInput): garment is WardrobeRef {
  return "wardrobeItemId" in garment;
}

export type TryonMode = "image" | "video";

export interface TryonParams {
  userId: string;
  avatar?: AvatarOverride;
  garments: GarmentInput[];
  mode: TryonMode;
  scenePrompt?: string;
  transitionPrompt?: string;
}

/*
 * Results carry `DailyUsage`, not a try-on-shaped subset of it. What a job
 * hands back is the caller's whole counter row for the day — every feature's
 * count, `chat_count` included — because that is what the client syncs its
 * usage cache from after any request that charges quota. Naming a try-on-local
 * copy of it made `chat_count` look like a stray field in a try-on type, when
 * the field is right and the ownership was wrong: the row belongs to the
 * counter, so `_shared/quota.ts` declares it and chat already publishes the
 * same one.
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
 * hands the core a capability instead. It is not a wall: `getAdminClient()` is
 * one import away for anything under `_shared/`. It makes the privileged step
 * the visible exception rather than an ambient possibility.
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
 * `scenePrompt`, `garmentDetails`, and `garmentFits` are grouped into one
 * options object rather than left as separate positional parameters:
 * `garmentDetails` and `garmentFits` are both `(string | undefined)[]`, so two
 * positionals of the same shape would let a caller transpose them and still
 * type-check — putting the wearer's body measurements under the garment's
 * appearance notes, or vice versa. A named object makes that transposition a
 * compile error instead of a silent prompt bug.
 *
 * The shape is `TaskPromptOptions` itself rather than a copy of it. A copy
 * would be structurally compatible while the two agreed, and — because every
 * field is optional — would stay compatible after one side renamed a field,
 * silently dropping that input on its way to the prompt. Sharing the
 * declaration makes a rename one edit instead of a convention.
 */
export type ImageGenerator = (
  avatarBase64: string,
  garmentGroups: string[][],
  opts?: TaskPromptOptions,
) => Promise<string | null>;

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
  client: SupabaseClient,
  ref: GarmentRef,
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
  client: SupabaseClient,
  userId: string,
  wardrobeItemId: string,
) => Promise<ResolvedGarment>;

/** Resolves the user's stored model photo into a loadable source. */
export type AvatarResolver = (
  client: SupabaseClient,
  userId: string,
) => Promise<ImageSource>;

/** Resolves the wearer's recorded body dimensions, or null when they have none. */
export type BodyResolver = (
  client: SupabaseClient,
  userId: string,
) => Promise<BodyMeasurements | null>;
