// supabase/functions/analyze-product-image/index.ts
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { getAdminClient, getAuthenticatedUserClient } from "../_shared/supabase.ts";
import {
  analyzeImage,
  checkImageAnalysisRateLimit,
  validateBase64,
} from "../_shared/image-analysis.ts";
import { json, jsonError } from "../_shared/http.ts";

const STYLE_VALUES = [
  "japanese", "korean", "western", "british", "chinese",
  "minimalist", "casual", "sporty", "lazy", "streetwear",
  "business", "preppy", "functional", "vintage", "artsy",
  "literary", "elegant", "mature", "neutral", "spicy", "sweet",
];
const GENDER_VALUES = ["male", "female", "unisex"];
const SEASON_VALUES = ["spring", "summer", "autumn", "winter"];
const THICKNESS_VALUES = ["low", "medium", "high"];
const ELASTICITY_VALUES = ["none", "low", "medium", "high"];
const FIT_VALUES = ["slim", "regular", "loose", "oversize"];

const str = (v: unknown): string | null =>
  typeof v === "string" && v.trim().length > 0 ? v.trim() : null;
const inList = (v: unknown, list: string[]): string | null =>
  typeof v === "string" && list.includes(v) ? v : null;
const filterList = (v: unknown, list: string[], cap: number): string[] =>
  Array.isArray(v)
    ? [...new Set(v.filter((x): x is string => typeof x === "string" && list.includes(x)))].slice(0, cap)
    : [];

function buildPrompt(categoryNames: string[]): string {
  return `你是電商商品標註助手。分析這張商品照片，輸出 JSON。無法判斷的欄位給 null（陣列給空陣列）。
- name：用繁體中文給簡潔的商品名稱建議（顏色+版型+材質+品類，例如「白色寬鬆棉質襯衫」），最多 20 字。
- category：從以下分類名稱「擇一」，無法判斷用 unknown：${categoryNames.join("、")}
- gender：male（男）/ female（女）/ unisex（中性）。
- styles：最多 3 個，輸出英文值：japanese 日系, korean 韓系, western 歐美, british 英式, chinese 中式, minimalist 簡約, casual 休閒, sporty 運動, lazy 慵懶, streetwear 街頭, business 商務, preppy 學院, functional 機能, vintage 復古, artsy 文青, literary 文藝, elegant 優雅, mature 輕熟, neutral 中性, spicy 辣妹, sweet 甜美。
- seasons：適合季節，可多選：spring 春, summer 夏, autumn 秋, winter 冬。
- material：從以下繁中擇一，無則 null：棉, 麻, 羊毛, 蠶絲, 聚酯纖維, 尼龍, 嫘縈, 天絲, 萊卡, 混紡。
- fit：版型，輸出英文值，無法判斷用 unknown：slim（合身）/ regular（常規）/ loose（寬鬆）/ oversize（超大寬版）。
- thickness：low（薄）/ medium（適中）/ high（厚），無法判斷用 unknown。
- elasticity：布料彈性，none（無彈性）/ low（低彈性）/ medium（中彈性）/ high（高彈性），無法判斷用 unknown。
只回 JSON，不要多餘文字。`;
}

function buildSchema(categoryNames: string[]): Record<string, unknown> {
  return {
    type: "OBJECT",
    properties: {
      name: { type: "STRING" },
      category: { type: "STRING", enum: [...categoryNames, "unknown"] },
      gender: { type: "STRING", enum: [...GENDER_VALUES, "unknown"] },
      styles: { type: "ARRAY", items: { type: "STRING", enum: STYLE_VALUES } },
      seasons: { type: "ARRAY", items: { type: "STRING", enum: SEASON_VALUES } },
      material: { type: "STRING" },
      fit: { type: "STRING", enum: [...FIT_VALUES, "unknown"] },
      thickness: { type: "STRING", enum: [...THICKNESS_VALUES, "unknown"] },
      elasticity: { type: "STRING", enum: [...ELASTICITY_VALUES, "unknown"] },
    },
    required: ["category", "gender", "styles", "seasons", "thickness", "elasticity"],
  };
}

Deno.serve(async (req) => {
  try {
    const { user, errorResponse } = await getAuthenticatedUserClient(req);
    if (errorResponse) return errorResponse;

    const body = await req.json().catch(() => null);
    const validation = validateBase64(body?.base64);
    if (!validation.ok) return validation.response;
    const base64 = validation.value;

    const limited = await checkImageAnalysisRateLimit(user!.id, "product_image_analysis");
    if (limited) return limited;

    // Load global categories and build a name -> ids map (server-side mapping).
    const admin = getAdminClient();
    const { data: categories, error: categoriesError } = await admin
      .from("product_categories")
      .select("id, name");
    if (categoriesError) {
      console.warn("analyze-product-image: failed to load product_categories", categoriesError);
    }
    const idByName = new Map<string, string>(
      (categories ?? []).map((c) => [c.name, c.id]),
    );
    const categoryNames = [...idByName.keys()];

    const parsed = await analyzeImage({
      base64,
      prompt: buildPrompt(categoryNames),
      schema: buildSchema(categoryNames),
    });

    const categoryName = str(parsed.category);
    const categoryId = categoryName ? (idByName.get(categoryName) ?? null) : null;
    const name = str(parsed.name);

    return json({
      name: name ? name.slice(0, 20) : null,
      categoryId,
      gender: inList(parsed.gender, GENDER_VALUES),
      styles: filterList(parsed.styles, STYLE_VALUES, 3),
      seasons: filterList(parsed.seasons, SEASON_VALUES, 4),
      material: str(parsed.material),
      fit: inList(parsed.fit, FIT_VALUES),
      thickness: inList(parsed.thickness, THICKNESS_VALUES),
      elasticity: inList(parsed.elasticity, ELASTICITY_VALUES),
    });
  } catch (err) {
    console.error("analyze-product-image error", err);
    return jsonError("Internal error", "INTERNAL", 500);
  }
});
