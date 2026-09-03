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
 * 不含 `data:` 前綴 —— edge function 的 `{ base64 }` 收的是純資料,連前綴一起送
 * 會讓解碼端拿到垃圾位元組。
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
 * 需要 R2 那個 bucket 對 LIFF 的 origin 開 CORS —— `<img src>` 不需要,fetch 需要。
 * 沒開的話這裡會丟,呼叫端要把它當成一次可以重試的失敗,而不是壞掉。
 *
 * `no-store` 不是為了拿最新的資料,是為了繞開快取裡那份不能用的複本:相片流的
 * `<img>` 先載過同一個網址,那是 no-cors、不送 Origin,所以 R2 照規矩沒回
 * `Access-Control-Allow-Origin`,而那份沒有 header 的回應進了快取。這裡再讀同一
 * 個網址時瀏覽器會拿它去做條件請求,R2 回 304,304 上一樣沒有那個 header,CORS
 * 檢查就失敗 —— 圖明明顯示得好好的,fetch 卻被擋。
 *
 * 另一條路是給那個 `<img>` 加上 `crossOrigin`,讓它一開始就存一份帶 header 的。
 * 沒有選它:那會讓「圖片顯示得出來」從此依賴 CORS 設定,而一個沒被列進
 * AllowedOrigins 的預覽網域就會讓所有結果圖變成破圖 —— 比一個功能失敗嚴重得多。
 */
export async function urlToBase64(url: string): Promise<string> {
  const resp = await fetch(url, { cache: "no-store" });
  if (!resp.ok) throw new Error(`failed to fetch image: ${resp.status}`);
  return blobToBase64(await resp.blob());
}
