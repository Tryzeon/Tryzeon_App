import { FunctionsHttpError } from "@supabase/supabase-js";

export class ApiError extends Error {
  constructor(message: string, readonly status: number) {
    super(message);
    this.name = "ApiError";
  }
}

/**
 * supabase-js 把非 2xx 包成 FunctionsHttpError,message 一律是那句
 * "Edge Function returned a non-2xx status code" —— 額度用完和生成失敗會長得
 * 一模一樣。要分開只能看 status,而 status 就在 `context` 這個 Response 上,
 * 同步可讀。
 *
 * 只取 status 不取 body 裡的 `code`:讀 body 是非同步的,而目前每一種要分開講
 * 的失敗(429 額度、422 生成失敗)光看 status 就夠了。
 */
export function toApiError(error: unknown): Error {
  if (!(error instanceof FunctionsHttpError)) {
    return error instanceof Error ? error : new Error(String(error));
  }
  const resp = error.context as Response;
  return new ApiError("request failed", resp.status);
}

export function tryonFailureMessage(err: unknown): string {
  if (err instanceof ApiError) {
    if (err.status === 429) return "今日試穿次數已用完，明天再回來試。";
    if (err.status === 422) return "這張照片沒能生成，請稍後再試。";
  }
  return "出了點狀況，請稍後再試。";
}
