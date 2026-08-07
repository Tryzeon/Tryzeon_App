import { SupabaseClient } from "jsr:@supabase/supabase-js@2";
import type { DailyUsage, UsageCounter } from "../quota.ts";

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

/** Try-on a catalog product by reference; the core resolves it to material. */
export interface GarmentRef {
  productId: string;
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

export interface TryonClients {
  /** Privileged client for the quota RPC and catalog lookups. */
  admin: SupabaseClient;
  /**
   * Client used to read `path` sources — garment images, and the
   * server-resolved avatar. Required — and required explicitly rather than
   * defaulted — because it is the only thing bounding which storage objects a
   * request can reach. An adapter that forwards client-supplied paths (the
   * app) MUST pass its user-scoped client so RLS applies; an adapter whose
   * paths are all server-derived (LINE) passes `admin` as a deliberate,
   * visible choice. Avatar paths are always produced by `resolveStoredAvatar`,
   * never by a caller.
   */
  materials: SupabaseClient;
}

export const LIMITS = {
  MAX_GARMENTS: 3,
  MAX_IMAGES_PER_GARMENT: 3,
  MAX_GARMENT_DETAIL_LENGTH: 500,
  MAX_PROMPT_LENGTH: 1000,
} as const;

/*
 * Ports the core depends on. `run.ts` is written against these signatures and
 * wires the Vertex AI / R2 implementations as its defaults, so swapping a
 * provider (or a test double) is a substitution rather than an edit to the
 * orchestrator.
 */

/**
 * Opens the quota counter for one user + mode. Takes the mode rather than a
 * feature name so the backend's vocabulary (`tryon` vs `tryon_video`) stays on
 * the implementation side of the port. The port it returns belongs to
 * `_shared/quota.ts` — the charge/refund contract is the counter's, not
 * try-on's, and chat opens the same one.
 */
export type QuotaFactory = (
  admin: SupabaseClient,
  userId: string,
  mode: TryonMode,
) => UsageCounter;

/**
 * Generates a try-on image; resolves to clean base64 image data (no data-URI
 * prefix — stripping any provider preamble is the implementation's job), or
 * null when the model returned no image.
 */
export type ImageGenerator = (
  avatarBase64: string,
  garmentGroups: string[][],
  scenePrompt?: string,
  garmentDetails?: (string | undefined)[],
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

/** Resolves a catalog product reference to trusted garment material. */
export type ProductResolver = (
  admin: SupabaseClient,
  productId: string,
) => Promise<ResolvedGarment>;

/**
 * Resolves a wardrobe item reference to trusted garment material. Takes the
 * owner as well as the id: unlike the catalog, which is public, a wardrobe read
 * is only correct when it is bound to whose wardrobe it is.
 */
export type WardrobeResolver = (
  admin: SupabaseClient,
  userId: string,
  wardrobeItemId: string,
) => Promise<ResolvedGarment>;

/** Resolves the user's stored model photo into a loadable source. */
export type AvatarResolver = (
  admin: SupabaseClient,
  userId: string,
) => Promise<ImageSource>;
