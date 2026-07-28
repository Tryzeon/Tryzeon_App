/**
 * The prompt, the response schema, and the sanitiser that turns whatever the
 * model said into the response body — the whole contract with the model, kept
 * apart from the HTTP shell in `index.ts` so it can be tested without a network.
 *
 * The three belong together: structured output types `category` as a string, so
 * the model has no way to answer "I can't tell" with JSON null. `unknown` is the
 * agreed spelling instead — the prompt teaches it, the schema permits it, and
 * the sanitiser strips it back out. Change one of the three and the other two
 * stop making sense.
 *
 * `tags` carries no enum, and the vocabulary the prompt lists is not enforced on
 * the way back. That list steers the model towards labels the rest of the
 * wardrobe already uses; it is not a storage constraint. A user may type any tag
 * they like (`upload_wardrobe_item_sheet.dart`), so `wardrobe_items.tags` is free
 * text, and filtering the model's answer against the list would only make the
 * AI's suggestions narrower than what the user can enter by hand.
 */

/** What the model answers with when the photo does not tell it. */
const UNKNOWN = "unknown";

/** Most tags one item carries. Stated to the model, enforced on the way back. */
const MAX_TAGS = 6;

/**
 * The categories a wardrobe item can land in — the values `wardrobe_items.category`
 * accepts. {@link UNKNOWN} is offered by the schema so the model has an explicit
 * "can't tell" option, and is absent here so it never reaches the response.
 */
const VALID_CATEGORIES = [
  "top",
  "bottoms",
  "outerwear",
  "sets",
  "others",
];
const SCHEMA_CATEGORIES = [...VALID_CATEGORIES, UNKNOWN];

export const ANALYSIS_PROMPT =
  `你是時尚衣物標註助手。分析這張單一衣物的照片，輸出 JSON。
- category 從以下擇一：top（上衣）, bottoms（下身，含褲子與裙子）, outerwear（外套）, sets（套裝/成套）, others（其他，含鞋子、配件及無法歸類者）；無法判斷用 ${UNKNOWN}。
- tags 以「繁體中文」輸出，最多 ${MAX_TAGS} 個，只能從下列受控詞彙挑選：
  顏色：黑、白、灰、米、棕、紅、橙、黃、綠、藍、紫、粉、金、銀
  風格：休閒、正式、運動、復古、簡約、甜美、街頭
  材質：棉、牛仔、針織、皮革、雪紡、羊毛、丹寧
  版型/圖案：素色、條紋、格紋、印花、拼接、寬鬆、合身
只回 JSON，不要多餘文字。`;

export const ANALYSIS_SCHEMA: Record<string, unknown> = {
  type: "object",
  properties: {
    category: { type: "string", enum: SCHEMA_CATEGORIES },
    tags: { type: "array", items: { type: "string" } },
  },
  required: ["category", "tags"],
};

export interface WardrobeAnalysisResponse {
  category: string | null;
  tags: string[];
}

/**
 * Narrows the model's answer to the response body. A category outside
 * {@link VALID_CATEGORIES} — the sentinel, a hallucinated name, a non-string,
 * an omitted field — comes back `null`, which the app reads as "leave this
 * input alone". Tags keep whatever non-empty strings the model produced, capped
 * at {@link MAX_TAGS}.
 */
export function toResponse(
  parsed: Record<string, unknown>,
): WardrobeAnalysisResponse {
  const category =
    typeof parsed.category === "string" && VALID_CATEGORIES.includes(parsed.category)
      ? parsed.category
      : null;

  const tags = Array.isArray(parsed.tags)
    ? parsed.tags
      .filter((t): t is string => typeof t === "string" && t.length > 0)
      .slice(0, MAX_TAGS)
    : [];

  return { category, tags };
}
