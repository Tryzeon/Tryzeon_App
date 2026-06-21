import { GoogleGenAI } from "npm:@google/genai";
import { getAIClient, VERTEX_CONFIG } from "./vertex-ai.ts";
import { detectMimeType } from "./image-utils.ts";

export const MAX_BASE64_LENGTH = 8 * 1024 * 1024;

/** Builds a JSON error response with the standard `{ error, code }` body. */
export function jsonError(message: string, code: string, status: number): Response {
  return new Response(
    JSON.stringify({ error: message, code }),
    { status, headers: { "Content-Type": "application/json" } },
  );
}

/** Standard 429 for the image-analysis rate limiters. */
export function rateLimitedResponse(): Response {
  return jsonError("Rate limit exceeded", "RATE_LIMIT_EXCEEDED", 429);
}

type ValidationResult =
  | { ok: true; value: string }
  | { ok: false; response: Response };

/** Validates a base64 image payload from a request body. */
export function validateBase64(base64: unknown): ValidationResult {
  if (typeof base64 !== "string" || base64.length < 16) {
    return { ok: false, response: jsonError("Missing or invalid base64", "BAD_REQUEST", 400) };
  }
  if (base64.length > MAX_BASE64_LENGTH) {
    return { ok: false, response: jsonError("Image payload too large", "PAYLOAD_TOO_LARGE", 413) };
  }
  return { ok: true, value: base64 };
}

/** Runs a single-image structured-output analysis and returns the parsed object. */
export async function analyzeImage<T extends Record<string, unknown> = Record<string, unknown>>(
  { base64, prompt, schema }: {
    base64: string;
    prompt: string;
    schema: Record<string, unknown>;
  },
): Promise<T> {
  const ai: GoogleGenAI = getAIClient();
  const result = await ai.models.generateContent({
    model: VERTEX_CONFIG.CHAT_MODEL!,
    contents: [
      {
        role: "user",
        parts: [
          { text: prompt },
          { inlineData: { mimeType: detectMimeType(base64), data: base64 } },
        ],
      },
    ],
    config: {
      responseMimeType: "application/json",
      responseSchema: schema,
    },
  });
  try {
    const parsed = JSON.parse(result.text ?? "{}");
    return (parsed && typeof parsed === "object") ? parsed as T : {} as T;
  } catch {
    return {} as T;
  }
}
