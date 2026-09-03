import { analyzeImage } from "../_shared/image-analysis.ts";
import { checkRateLimit } from "../_shared/rate-limit.ts";

/**
 * The note is replayed to the model on every subsequent turn, so an unbounded
 * description would crowd out the conversation it is context for. Counted by
 * code point rather than UTF-16 code unit: the prompt invites free description
 * of a non-garment photo, where an astral character is reachable.
 */
const MAX_DESCRIPTION_CHARS = 20;

/**
 * Kept apart from the app's `wardrobe_image_analysis` bucket so a LINE spike
 * cannot starve the app's wardrobe uploads; the numbers match the app's. This is
 * the one model call in the webhook that no daily quota bounds.
 */
const RATE_BUCKET = "line_garment_analysis";
const PER_MINUTE = 15;
const PER_DAY = 200;

export const ANALYSIS_PROMPT =
  `你是時尚衣物標註助手。用一個繁體中文名詞短語描述這張照片裡的衣物，涵蓋顏色、版型、材質、品項，例如「淺藍色寬鬆棉質抽繩長褲」。最多 ${MAX_DESCRIPTION_CHARS} 字。
若照片主體不是衣物，如實描述你看到的東西。
只回 JSON，不要多餘文字。`;

export const ANALYSIS_SCHEMA: Record<string, unknown> = {
  type: "object",
  properties: {
    description: { type: "string" },
  },
  required: ["description"],
};

/**
 * Declared structurally rather than as `typeof analyzeImage` so a double need
 * not reproduce that function's generic parameter.
 */
export interface DescribeGarmentDeps {
  analyze?: (
    args: { base64: string; prompt: string; schema: Record<string, unknown> },
  ) => Promise<Record<string, unknown>>;
  checkLimit?: (
    userId: string,
    bucket: string,
    limit: number,
    windowSeconds: number,
  ) => Promise<boolean>;
}

/**
 * Never throws, and that is the contract the caller is written against: an
 * outage, a spent budget or an unreadable answer all degrade to `null`, leaving
 * the try-on running alongside untouched.
 */
export async function describeGarment(
  userId: string,
  base64: string,
  deps: DescribeGarmentDeps = {},
): Promise<string | null> {
  const checkLimit = deps.checkLimit ?? checkRateLimit;
  const analyze = deps.analyze ?? analyzeImage;

  if (!await checkLimit(userId, `${RATE_BUCKET}:minute`, PER_MINUTE, 60)) {
    console.warn("line-webhook garment analysis rate limited (minute):", userId);
    return null;
  }
  if (!await checkLimit(userId, `${RATE_BUCKET}:day`, PER_DAY, 86400)) {
    console.warn("line-webhook garment analysis rate limited (day):", userId);
    return null;
  }

  try {
    const parsed = await analyze({
      base64,
      prompt: ANALYSIS_PROMPT,
      schema: ANALYSIS_SCHEMA,
    });
    const description = typeof parsed.description === "string"
      ? parsed.description.trim()
      : "";
    if (!description) return null;

    const chars = [...description];
    return chars.length > MAX_DESCRIPTION_CHARS
      ? `${chars.slice(0, MAX_DESCRIPTION_CHARS).join("")}…`
      : description;
  } catch (err) {
    console.warn("line-webhook garment analysis failed:", err);
    return null;
  }
}
