import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { GoogleGenAI } from "npm:@google/genai";
import { getAuthenticatedUserClient, getAdminClient } from "../_shared/supabase.ts";
import { getAIClient, VERTEX_CONFIG } from "../_shared/vertex-ai.ts";
import { detectMimeType } from "../_shared/image-utils.ts";
import { checkRateLimit } from "../_shared/rate-limit.ts";

// "unknown" is a sentinel the model may emit but is never a real category;
// keep it in the schema enum so the model has an explicit "can't tell" option,
// but exclude it from the values we accept back.
const VALID_CATEGORIES = [
  "top",
  "bottoms",
  "outerwear",
  "sets",
  "others",
];
const SCHEMA_CATEGORIES = [...VALID_CATEGORIES, "unknown"];

const MAX_BASE64_LENGTH = 8 * 1024 * 1024;

function rateLimitedResponse(): Response {
  return new Response(
    JSON.stringify({ error: "Rate limit exceeded", code: "RATE_LIMIT_EXCEEDED" }),
    { status: 429, headers: { "Content-Type": "application/json" } },
  );
}

const ANALYSIS_PROMPT =
  `你是時尚衣物標註助手。分析這張單一衣物的照片，輸出 JSON。
- category 從以下擇一：top（上衣）, bottoms（下身，含褲子與裙子）, outerwear（外套）, sets（套裝/成套）, others（其他，含鞋子、配件及無法歸類者）；無法判斷用 unknown。
- tags 以「繁體中文」輸出，最多 6 個，只能從下列受控詞彙挑選：
  顏色：黑、白、灰、米、棕、紅、橙、黃、綠、藍、紫、粉、金、銀
  風格：休閒、正式、運動、復古、簡約、甜美、街頭
  材質：棉、牛仔、針織、皮革、雪紡、羊毛、丹寧
  版型/圖案：素色、條紋、格紋、印花、拼接、寬鬆、合身
只回 JSON，不要多餘文字。`;

// @google/genai does not export a Type enum in the version used by this project;
// use string-literal type descriptors for the structured-output schema instead.
const ANALYSIS_SCHEMA = {
  type: "OBJECT",
  properties: {
    category: { type: "STRING", enum: SCHEMA_CATEGORIES },
    tags: { type: "ARRAY", items: { type: "STRING" } },
  },
  required: ["category", "tags"],
};

Deno.serve(async (req) => {
  try {
    const { user, errorResponse } = await getAuthenticatedUserClient(req);
    if (errorResponse) return errorResponse;

    const body = await req.json().catch(() => null);
    const base64: string | undefined = body?.base64;
    if (!base64 || typeof base64 !== "string" || base64.length < 16) {
      return new Response(
        JSON.stringify({ error: "Missing or invalid base64", code: "BAD_REQUEST" }),
        { status: 400, headers: { "Content-Type": "application/json" } },
      );
    }
    if (base64.length > MAX_BASE64_LENGTH) {
      return new Response(
        JSON.stringify({ error: "Image payload too large", code: "PAYLOAD_TOO_LARGE" }),
        { status: 413, headers: { "Content-Type": "application/json" } },
      );
    }

    const adminClient = getAdminClient();
    const okMinute = await checkRateLimit(
      adminClient,
      user!.id,
      "image_analysis:minute",
      15,
      60,
    );
    
    if (!okMinute) return rateLimitedResponse();
    const okDay = await checkRateLimit(
      adminClient,
      user!.id,
      "image_analysis:day",
      200,
      86400,
    );
    if (!okDay) return rateLimitedResponse();

    const ai: GoogleGenAI = getAIClient();
    const result = await ai.models.generateContent({
      model: VERTEX_CONFIG.CHAT_MODEL!,
      contents: [
        {
          role: "user",
          parts: [
            { text: ANALYSIS_PROMPT },
            { inlineData: { mimeType: detectMimeType(base64), data: base64 } },
          ],
        },
      ],
      config: {
        responseMimeType: "application/json",
        responseSchema: ANALYSIS_SCHEMA,
      },
    });

    let parsed: { category?: string; tags?: unknown };
    try {
      parsed = JSON.parse(result.text ?? "{}");
    } catch {
      parsed = {};
    }

    const category =
      typeof parsed.category === "string" && VALID_CATEGORIES.includes(parsed.category)
        ? parsed.category
        : null;
    const tags = Array.isArray(parsed.tags)
      ? parsed.tags
        .filter((t): t is string => typeof t === "string" && t.length > 0)
        .slice(0, 6)
      : [];

    return new Response(
      JSON.stringify({ tags, category }),
      { headers: { "Content-Type": "application/json" } },
    );
  } catch (err) {
    console.error("analyze-wardrobe-image error", err);
    return new Response(
      JSON.stringify({ error: "Internal error", code: "INTERNAL" }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }
});
