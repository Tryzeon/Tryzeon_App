import { supabase } from "../lib/supabase";
import { toApiError } from "./errors";

export type Garment = { productId: string } | { images: { base64: string }[] };

export interface TryonOptions {
  avatarBase64?: string;
  scenePrompt?: string;
  stylingPrompt?: string;
}

/**
 * `tryon` edge function 的 wire body。只有 image —— 影片試穿在 LIFF 上還沒開,
 * 那條路是一個 ~5 分鐘的同步請求,webview 被切走就會永久掉結果。
 */
interface TryonBody extends TryonOptions {
  mode: "image";
  garments: Garment[];
  avatar?: { base64: string };
}

/**
 * 呼叫的是 app 用的同一個 tryon function,JWT 由 supabase-js 帶上,所以整個 job
 * 跑在 RLS 之下。省略的欄位就是「不指定」—— 空字串會被後端當成一段真的 prompt,
 * 而少了 avatar 時 core 會去讀 profile 上那張,那才是唯一不會過期的一份。
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
