import { SupabaseClient } from "jsr:@supabase/supabase-js@2";
import { downloadPublicImageFromR2 } from "./r2.ts";

export function uint8ToBase64(bytes: Uint8Array): string {
  return btoa(Array.from(bytes, (b) => String.fromCharCode(b)).join(""));
}

/**
 * Downloads an image (Supabase Storage or Cloudflare R2 public bucket) and
 * returns it as base64. R2 is used for keys starting with `stores/` (store
 * logos and product images); Supabase Storage is used for wardrobe and avatar
 * paths.
 */
export async function fetchImageAsBase64(supabase: SupabaseClient, path: string): Promise<string> {
  if (path.startsWith("stores/")) {
    const bytes = await downloadPublicImageFromR2(path);
    return uint8ToBase64(bytes);
  }

  const folderToBucketMap: Record<string, string> = {
    "wardrobe": "wardrobe-images",
    "avatar": "user-avatars",
  };

  const segments = path.split('/');
  const folder = segments.find(segment => folderToBucketMap.hasOwnProperty(segment));

  if (!folder) {
    throw new Error(`Invalid path structure: ${path}. No valid folder segment found. Expected R2 prefix (stores/) or Supabase folder: ${Object.keys(folderToBucketMap).join(", ")}`);
  }

  const bucket = folderToBucketMap[folder];

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

/**
 * Detects the MIME type of an image from its base64-encoded data.
 * Reads the first few bytes to identify PNG / JPEG / WEBP.
 * Defaults to image/jpeg if no signature matches.
 */
export function detectMimeType(base64Data: string): string {
  const header = atob(base64Data.slice(0, 16));
  if (header.startsWith("\x89PNG")) return "image/png";
  if (header.startsWith("\xFF\xD8\xFF")) return "image/jpeg";
  if (header.slice(0, 4) === "RIFF" && header.slice(8, 12) === "WEBP") {
    return "image/webp";
  }
  return "image/jpeg";
}

/**
 * Maps an image MIME type to a file extension (no leading dot).
 */
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

/**
 * Decodes a base64 string into a Uint8Array.
 * Input must be clean base64 (no data-URI prefix).
 */
export function base64ToUint8Array(base64: string): Uint8Array {
  const binaryString = atob(base64);
  const bytes = new Uint8Array(binaryString.length);
  for (let i = 0; i < binaryString.length; i++) {
    bytes[i] = binaryString.charCodeAt(i);
  }
  return bytes;
}
