export const JPEG_MIME = "image/jpeg";
export const JPEG_EXTENSION = "jpg";

export function downscaleDimensions(
  width: number,
  height: number,
  max: number,
): { width: number; height: number } {
  const longest = Math.max(width, height);
  if (longest <= max) return { width, height };
  const scale = max / longest;
  return { width: Math.round(width * scale), height: Math.round(height * scale) };
}

export function downscaleToBlob(file: File, maxDim = 1024): Promise<Blob> {
  return new Promise((resolve, reject) => {
    const url = URL.createObjectURL(file);
    const img = new Image();
    img.onload = () => {
      const { width, height } = downscaleDimensions(img.width, img.height, maxDim);
      const canvas = document.createElement("canvas");
      canvas.width = width;
      canvas.height = height;
      const ctx = canvas.getContext("2d");
      if (!ctx) {
        URL.revokeObjectURL(url);
        reject(new Error("canvas 2d context unavailable"));
        return;
      }
      ctx.drawImage(img, 0, 0, width, height);
      URL.revokeObjectURL(url);
      canvas.toBlob(
        (blob) => {
          if (blob) resolve(blob);
          else reject(new Error("canvas produced no blob"));
        },
        JPEG_MIME,
        0.9,
      );
    };
    img.onerror = () => {
      URL.revokeObjectURL(url);
      reject(new Error("failed to load image"));
    };
    img.src = url;
  });
}

/**
 * Without the `data:` prefix — the edge function's `{ base64 }` expects raw
 * data, and sending the prefix along hands the decoder garbage bytes.
 */
export function blobToBase64(blob: Blob): Promise<string> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => {
      const result = reader.result as string;
      const comma = result.indexOf(",");
      resolve(comma === -1 ? result : result.slice(comma + 1));
    };
    reader.onerror = () => reject(reader.error ?? new Error("failed to read blob"));
    reader.readAsDataURL(blob);
  });
}

export async function downscaleToBase64(file: File, maxDim = 1024): Promise<string> {
  return blobToBase64(await downscaleToBlob(file, maxDim));
}

/**
 * Requires the R2 bucket to allow CORS from the LIFF origin — `<img src>` does
 * not need it, fetch does. Without it this throws, and callers should treat that
 * as a retryable failure rather than a broken state.
 *
 * `no-store` is not about getting fresh data, it is about bypassing the unusable
 * copy in the cache: the photo stream's `<img>` already loaded the same URL
 * no-cors, without an Origin header, so R2 correctly answered without
 * `Access-Control-Allow-Origin`, and that header-less response went into the
 * cache. Reading the same URL here makes the browser revalidate against it, R2
 * replies 304, the 304 likewise carries no such header, and the CORS check fails
 * — the image displays fine, yet the fetch is blocked.
 *
 * The other route is putting `crossOrigin` on that `<img>` so it caches a copy
 * with the header from the start. Not taken: that would make "the image renders
 * at all" depend on CORS configuration, and a preview domain missing from
 * AllowedOrigins would break every result image — far worse than one failing
 * feature.
 */
export async function urlToBase64(url: string): Promise<string> {
  const resp = await fetch(url, { cache: "no-store" });
  if (!resp.ok) throw new Error(`failed to fetch image: ${resp.status}`);
  return blobToBase64(await resp.blob());
}
