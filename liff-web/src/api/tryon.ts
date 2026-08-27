import { supabase } from "../lib/supabase";
import { toApiError } from "./errors";

/**
 * 用使用者存好的 model 照跑一次試穿,回傳結果圖的網址。
 *
 * 呼叫的是 app 用的同一個 tryon function,JWT 由 supabase-js 帶上,所以整個 job
 * 跑在 RLS 之下。body 不帶 avatar 是刻意的:省略時 core 會去讀 profile 上的那
 * 張 —— 一份 client 手上的路徑複本只會過期。
 */
export async function callTryon(productId: string): Promise<string> {
  const { data, error } = await supabase.functions.invoke("tryon", {
    body: { garments: [{ productId }], mode: "image" },
  });
  if (error) throw toApiError(error);

  const imageUrl = (data as { imageUrl?: unknown } | null)?.imageUrl;
  if (typeof imageUrl !== "string" || imageUrl.length === 0) {
    throw new Error("tryon response missing imageUrl");
  }
  return imageUrl;
}
