/**
 * How this channel asks the model what a forwarded photo shows, and how often
 * it may ask.
 *
 * The wardrobe endpoint (`analyze-wardrobe-image/analysis.ts`) already labels
 * garment photos, but its tags come from a controlled vocabulary so
 * `wardrobe_items.tags` stays filterable by `search_wardrobe`'s `.contains()`:
 * a 淺藍色寬鬆棉質抽繩長褲 survives it as `bottoms / 藍、寬鬆、棉`. Here the answer
 * is read by a language model, not a query planner — "淺" and "抽繩" are exactly
 * what make the follow-up search land, and a vocabulary built for SQL throws
 * them away.
 *
 * So the prompt asks for one dense phrase and the schema carries one field.
 * What it deliberately does NOT do is pre-resolve the answer into
 * `search_products`' parameters (`styles`, `fits`, `seasons` — see
 * `_shared/chat/tools.ts`): the agent already holds that tool's full schema and
 * can map prose onto it, whereas naming those enums here would create two
 * places that must agree with nothing to enforce it.
 *
 * There is no "is this even a garment?" flag either. A photo of a dog degrades
 * gracefully — the model describes the dog, the note records it, and the agent
 * works out next turn that the user sent the wrong picture — where a flag would
 * buy a branch and two more test paths.
 */
import { analyzeImage } from "../_shared/image-analysis.ts";
import { checkRateLimit } from "../_shared/rate-limit.ts";

/**
 * Longest description that reaches the transcript, in code points.
 *
 * Not cosmetic: this note is replayed to the model on every subsequent turn, so
 * an unbounded "這是一件淺藍色的寬鬆版型棉質長褲，腰部有抽繩設計，適合休閒場合…"
 * would crowd out the conversation it is supposed to be context for. The prompt
 * asks for the cap and the code enforces it, the belt and braces
 * `clampProductName` applies in `product-card.ts`; the trailing `…` keeps a
 * truncated phrase from reading to the model as a complete one. Counted by code
 * point rather than `String.prototype.slice`'s UTF-16 code units, since the
 * prompt invites free description of a non-garment photo, where an astral
 * character (emoji, rare CJK) is reachable.
 */
const MAX_DESCRIPTION_CHARS = 20;

/**
 * This channel's analysis budget, kept apart from the app's
 * `wardrobe_image_analysis` bucket. The two see different traffic, and pooling
 * them would let a LINE spike starve the app's wardrobe uploads. Numbers match
 * the app's, since it is the same kind of call.
 *
 * A budget is needed here at all because this is the one model call in the
 * webhook that no daily quota bounds: `runTryonJob` refuses to generate once
 * `tryon` is spent, but analysis runs alongside it and would keep running for a
 * sender who has nothing left to spend.
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
 * The two collaborators a test substitutes. Declared structurally rather than
 * as `typeof analyzeImage` so a double need not reproduce that function's
 * generic parameter.
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
 * What the photo shows, in one phrase, or `null` when there is nothing usable
 * to record.
 *
 * Never throws, and that is the contract the caller is written against: the
 * description is an enhancement to the transcript, while the try-on running
 * alongside it is what the user actually asked for. An outage, a spent budget or
 * an unreadable answer all degrade to the same `null` — no note, same try-on,
 * the fail-open judgement `redisConversations` makes for the same reason.
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
