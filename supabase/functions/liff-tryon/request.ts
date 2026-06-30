export class ValidationError extends Error {}

export interface LiffTryonBody {
  idToken: string;
  avatarBase64: string;
  productId: string;
}

function requireString(value: unknown, label: string): string {
  if (typeof value !== "string" || value.length === 0) {
    throw new ValidationError(`${label} is required`);
  }
  return value;
}

export function parseLiffTryonBody(body: unknown): LiffTryonBody {
  if (typeof body !== "object" || body === null) {
    throw new ValidationError("body must be an object");
  }
  const b = body as Record<string, unknown>;
  return {
    idToken: requireString(b.idToken, "idToken"),
    avatarBase64: requireString(b.avatarBase64, "avatarBase64"),
    productId: requireString(b.productId, "productId"),
  };
}

export function corsHeaders(): Record<string, string> {
  const origin = Deno.env.get("LIFF_WEB_ORIGIN") ?? "*";
  return {
    "Access-Control-Allow-Origin": origin,
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, Authorization",
  };
}
