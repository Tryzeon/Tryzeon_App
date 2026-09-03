import { FunctionsHttpError } from "@supabase/supabase-js";

export class ApiError extends Error {
  constructor(message: string, readonly status: number) {
    super(message);
    this.name = "ApiError";
  }
}

/**
 * supabase-js wraps every non-2xx in a FunctionsHttpError whose message is
 * always "Edge Function returned a non-2xx status code" — a used-up quota and a
 * failed generation look identical. Telling them apart means reading the status,
 * which sits on the `context` Response and can be read synchronously.
 *
 * Takes the status only, not the `code` in the body: reading the body is async,
 * and every failure that currently needs its own wording (429 quota, 422
 * generation failure) is already distinguishable by status alone.
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
