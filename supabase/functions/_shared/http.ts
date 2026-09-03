import { CORE_ERROR_CODE, type CoreErrorInfo } from "./errors.ts";

const JSON_HEADERS = { "Content-Type": "application/json" } as const;

export function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), { status, headers: JSON_HEADERS });
}

export function jsonError(message: string, code: string, status: number): Response {
  return json({ error: message, code }, status);
}

export function jsonRateLimited(usage?: unknown): Response {
  const code = CORE_ERROR_CODE.quota;
  return json(
    usage === undefined
      ? { error: "Rate limit exceeded", code }
      : { error: "Rate limit exceeded", code, usage },
    429,
  );
}

export function coreErrorResponse(info: CoreErrorInfo): Response {
  switch (info.kind) {
    case "validation":
      return jsonError(info.message, CORE_ERROR_CODE.validation, 400);
    case "quota":
      return jsonRateLimited(info.usage);
    case "busy":
      return jsonError(
        "Service is busy, please try again shortly",
        CORE_ERROR_CODE.busy,
        503,
      );
  }
}
