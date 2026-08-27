/** 縮圖輸出格式。儲存路徑的副檔名與 contentType 都依賴這兩個值。 */
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

/**
 * 讀一個 File,把長邊縮到 maxDim 以內,輸出 JPEG Blob。
 *
 * 從前這裡輸出 base64,因為照片要塞進 edge function 的 JSON body。改成直傳
 * Storage 之後 base64 就只剩壞處 —— 多 33% 的傳輸量,而 Storage 收的本來就是
 * 二進位。
 */
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
