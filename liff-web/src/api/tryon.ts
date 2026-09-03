import { supabase } from "../lib/supabase";
import { toApiError } from "./errors";

export type Garment = { productId: string } | { images: { base64: string }[] };

export interface TryonOptions {
  avatarBase64?: string;
  scenePrompt?: string;
  stylingPrompt?: string;
}

/**
 * Image only — video try-on is not enabled on LIFF: that path is a ~5 minute
 * synchronous request, and the result is lost for good if the webview is
 * backgrounded.
 */
interface TryonBody extends TryonOptions {
  mode: "image";
  garments: Garment[];
  avatar?: { base64: string };
}

/**
 * Calls the same tryon function the app uses, with the JWT attached by
 * supabase-js, so the whole job runs under RLS. An omitted field means
 * "unspecified" — an empty string would be taken by the backend as a real
 * prompt, and without an avatar the core reads the one on the profile, which is
 * the only copy that never expires.
 */
export async function runTryon(
  garment: Garment,
  { avatarBase64, scenePrompt, stylingPrompt }: TryonOptions = {},
): Promise<string> {
  const body: TryonBody = {
    mode: "image",
    garments: [garment],
    ...(avatarBase64 ? { avatar: { base64: avatarBase64 } } : {}),
    ...(scenePrompt ? { scenePrompt } : {}),
    ...(stylingPrompt ? { stylingPrompt } : {}),
  };

  const { data, error } = await supabase.functions.invoke("tryon", { body });
  if (error) throw toApiError(error);

  const imageUrl = (data as { imageUrl?: unknown } | null)?.imageUrl;
  if (typeof imageUrl !== "string" || imageUrl.length === 0) {
    throw new Error("tryon response missing imageUrl");
  }
  return imageUrl;
}
