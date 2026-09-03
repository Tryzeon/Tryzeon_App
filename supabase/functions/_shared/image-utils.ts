import { downloadPublicImageFromR2 } from "./r2.ts";
import { isR2PublicKey, type SupabaseImageBucket } from "./storage.ts";
import type { DbClient } from "./supabase.ts";

export function uint8ToBase64(bytes: Uint8Array): string {
  return btoa(Array.from(bytes, (b) => String.fromCharCode(b)).join(""));
}

export async function fetchImageAsBase64(
  supabase: DbClient,
  path: string,
  bucket: SupabaseImageBucket,
): Promise<string> {
  if (isR2PublicKey(path)) {
    const bytes = await downloadPublicImageFromR2(path);
    return uint8ToBase64(bytes);
  }

  const { data, error } = await supabase.storage.from(bucket).download(path);

  if (error) {
    throw new Error(`Failed to download image from ${bucket}/${path}: ${error.message}`);
  }

  if (!data) {
    throw new Error(`No data returned for image: ${bucket}/${path}`);
  }

  const arrayBuffer = await data.arrayBuffer();
  return uint8ToBase64(new Uint8Array(arrayBuffer));
}

export function detectMimeType(base64Data: string): string {
  const header = atob(base64Data.slice(0, 16));
  if (header.startsWith("\x89PNG")) return "image/png";
  if (header.startsWith("\xFF\xD8\xFF")) return "image/jpeg";
  if (header.slice(0, 4) === "RIFF" && header.slice(8, 12) === "WEBP") {
    return "image/webp";
  }
  return "image/jpeg";
}

export function mimeTypeToExtension(mimeType: string): string {
  switch (mimeType) {
    case "image/png":
      return "png";
    case "image/webp":
      return "webp";
    case "image/jpeg":
    default:
      return "jpg";
  }
}

/** Input must be clean base64 — a data-URI prefix is not stripped. */
export function base64ToUint8Array(base64: string): Uint8Array {
  const binaryString = atob(base64);
  const bytes = new Uint8Array(binaryString.length);
  for (let i = 0; i < binaryString.length; i++) {
    bytes[i] = binaryString.charCodeAt(i);
  }
  return bytes;
}
