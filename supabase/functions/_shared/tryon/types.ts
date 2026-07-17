import { SupabaseClient } from "jsr:@supabase/supabase-js@2";

export interface ImageSource {
  path?: string;
  base64?: string;
}

export interface GarmentInput {
  images: ImageSource[];
  detail?: string;
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

export type TryonResult =
  | { kind: "image"; imageUrl: string; usage: unknown }
  | { kind: "video"; videoUrl: string; usage: unknown };

export interface TryonClients {
  /** Privileged client for the quota RPC. */
  admin: SupabaseClient;
  /**
   * Client used to read avatar/garment `path` sources. Defaults to `admin`.
   * The app passes its user-scoped client so RLS bounds which storage paths a
   * request can read; server-derived callers (LINE) may omit it.
   */
  materials?: SupabaseClient;
}

export const LIMITS = {
  MAX_GARMENTS: 3,
  MAX_IMAGES_PER_GARMENT: 3,
  MAX_GARMENT_DETAIL_LENGTH: 500,
} as const;

export class ValidationError extends Error {}

export class QuotaExceededError extends Error {
  constructor(public usage: unknown) {
    super("quota exceeded");
  }
}

export class GenerationFailedError extends Error {}
