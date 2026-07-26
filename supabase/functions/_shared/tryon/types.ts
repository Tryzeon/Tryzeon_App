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

/** Try-on a catalog product by reference; the core resolves it to material. */
export interface GarmentRef {
  productId: string;
}

/** A garment described directly by the user's own image sources. */
export interface GarmentMaterial {
  images: ImageSource[];
}

/**
 * Garment material as the model will finally see it: the sources, plus the
 * description built for a catalog product.
 *
 * `detail` lives here and not on `GarmentMaterial` because nothing outside the
 * server produces one. Leaving the field on the input type would advertise a
 * way to write arbitrary text into the prompt that no caller uses and no client
 * should have; here, the only thing that can set it is `resolveProductGarment`,
 * which runs after validation.
 */
export interface ResolvedGarment extends GarmentMaterial {
  detail?: string;
}

/**
 * A garment is either a product reference (resolved server-side against the
 * catalog) or user-supplied material. Product concept stays a first-class
 * domain source, not an adapter concern.
 */
export type GarmentInput = GarmentRef | GarmentMaterial;

/** True when a garment is a product reference (a real `productId` string). */
export function isGarmentRef(garment: GarmentInput): garment is GarmentRef {
  return "productId" in garment;
}

export type TryonMode = "image" | "video";

export interface TryonParams {
  userId: string;
  avatar: ImageSource;
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
   * Client used to read avatar/garment `path` sources. Required — and required
   * explicitly rather than defaulted — because it is the only thing bounding
   * which storage objects a request can reach. An adapter that forwards
   * client-supplied paths (the app) MUST pass its user-scoped client so RLS
   * applies; an adapter whose paths are all server-derived (LINE) passes
   * `admin` as a deliberate, visible choice.
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
