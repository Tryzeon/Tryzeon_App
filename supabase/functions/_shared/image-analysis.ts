import { generateObject, jsonSchema } from "ai";
import { vertexModel } from "./vertex/provider.ts";
import { chatModel } from "./vertex/config.ts";
import { detectMimeType } from "./image-utils.ts";
import { jsonError, jsonRateLimited } from "./http.ts";
import { checkRateLimit } from "./rate-limit.ts";

export const MAX_BASE64_LENGTH = 8 * 1024 * 1024;

type ValidationResult =
  | { ok: true; value: string }
  | { ok: false; response: Response };

export function validateBase64(base64: unknown): ValidationResult {
  if (typeof base64 !== "string" || base64.length < 16) {
    return { ok: false, response: jsonError("Missing or invalid base64", "BAD_REQUEST", 400) };
  }
  if (base64.length > MAX_BASE64_LENGTH) {
    return { ok: false, response: jsonError("Image payload too large", "PAYLOAD_TOO_LARGE", 413) };
  }
  return { ok: true, value: base64 };
}

export async function checkImageAnalysisRateLimit(
  userId: string,
  bucketPrefix: string,
): Promise<Response | null> {
  const okMinute = await checkRateLimit(userId, `${bucketPrefix}:minute`, 15, 60);
  if (!okMinute) return jsonRateLimited();
  const okDay = await checkRateLimit(userId, `${bucketPrefix}:day`, 200, 86400);
  if (!okDay) return jsonRateLimited();
  return null;
}

/**
 * Raises when the model returns nothing matching `schema`. A caller cannot tell
 * an empty object meaning "no attributes found" from one meaning "the model
 * failed", so an unreadable answer is reported rather than flattened into the
 * same shape as a successful one.
 */
export async function analyzeImage<T extends Record<string, unknown> = Record<string, unknown>>(
  { base64, prompt, schema }: {
    base64: string;
    prompt: string;
    schema: Record<string, unknown>;
  },
): Promise<T> {
  const { object } = await generateObject({
    model: vertexModel(chatModel()),
    schema: jsonSchema<T>(schema),
    messages: [
      {
        role: "user",
        content: [
          { type: "text", text: prompt },
          { type: "file", mediaType: detectMimeType(base64), data: base64 },
        ],
      },
    ],
  });
  return object;
}
