import { tool } from "npm:ai@^6.0.208";
import { z } from "npm:zod@^4.4.3";
import { SupabaseClient } from "jsr:@supabase/supabase-js@2";
import {
  mapSearchProductsArgs,
  resolveCategoryFilter,
  SEARCH_LIMIT,
  toSearchResultItem,
  WARDROBE_SELECT,
} from "./logic.ts";
import { nonEmptyStr } from "../text.ts";

// The error case is returned, not thrown: a throw would abort the agent loop,
// whereas an empty result carrying the reason lets the model correct the name
// (or drop the filter) and search again, which the system prompt already asks
// it to do when a search comes back empty.
type SearchProductsResult = {
  items: Record<string, any>[];
  error?: string;
};

async function runSearchProducts(
  admin: SupabaseClient,
  args: Record<string, any>,
  categoryIdByName: Map<string, string>,
): Promise<SearchProductsResult> {
  const category = resolveCategoryFilter(args.category_name, categoryIdByName);
  if (!category.ok) {
    return { items: [], error: category.error };
  }
  const params = mapSearchProductsArgs(args, { categoryIds: category.categoryIds });
  const { data, error } = await admin.rpc("list_shop_products", params);
  if (error) throw error;
  return { items: ((data ?? []) as Record<string, any>[]).map(toSearchResultItem) };
}

async function runSearchWardrobe(
  admin: SupabaseClient,
  userId: string,
  args: Record<string, any>,
): Promise<Record<string, any>[]> {
  let q = admin
    .from("wardrobe_items")
    .select(WARDROBE_SELECT)
    .eq("user_id", userId)
    .order("created_at", { ascending: false })
    .limit(SEARCH_LIMIT);
  const category = nonEmptyStr(args.category);
  if (category) q = q.eq("category", category);
  if (Array.isArray(args.tags) && args.tags.length > 0) {
    q = q.contains("tags", args.tags);
  }
  const { data, error } = await q;
  if (error) throw error;
  return (data ?? []) as Record<string, any>[];
}

// The tool schemas are request-independent — only the `execute` closures below
// bind a client and a user — so they are built once per isolate rather than on
// every turn, along with the JSON Schema the SDK derives from each.
const SEARCH_PRODUCTS_SCHEMA = z.object({
  query: z.string().optional().describe(
    "只比對『商品名稱』與『店家/品牌名稱』。多個詞以空白分隔，且每個詞都必須出現在商品名稱中（AND），所以請用少量、可能出現在名稱裡的字（如『襯衫』『洋裝』或品牌名）。顏色、材質、風格、季節、分類請勿放這裡——改用對應參數。",
  ),
  category_name: z.string().optional().describe("商品分類名稱，需與分類清單一致"),
  gender: z.string().optional().describe(
    "選填。依商品適用性別篩選，只能用：male, female, unisex。可參考使用者資訊自行決定是否使用。",
  ),
  materials: z.array(z.string()).optional().describe(
    "選填。材質關鍵字（自由文字，子字串比對），如 棉、麻、羊毛、聚酯纖維。",
  ),
  styles: z.array(z.string()).optional().describe(
    "選填。風格，只能用這些固定英文值：japanese, korean, western, british, chinese, minimalist, casual, sporty, lazy, streetwear, business, preppy, functional, vintage, artsy, literary, elegant, mature, neutral, spicy, sweet。",
  ),
  seasons: z.array(z.string()).optional().describe(
    "選填。季節，只能用：spring, summer, autumn, winter。",
  ),
  fits: z.array(z.string()).optional().describe(
    "選填。版型，只能用這些固定英文值：slim（合身）, regular（常規）, loose（寬鬆）, oversize（超大寬版）。",
  ),
  elasticities: z.array(z.string()).optional().describe(
    "選填。彈性，只能用：none, low, medium, high。",
  ),
  thicknesses: z.array(z.string()).optional().describe(
    "選填。厚度，只能用：low, medium, high。",
  ),
  channels: z.array(z.string()).optional().describe(
    "選填。購物管道，只能用：physical（實體店面）, online（線上）。",
  ),
  min_price: z.number().optional().describe("選填。價格下限。"),
  max_price: z.number().optional().describe("選填。價格上限。"),
});

const SEARCH_WARDROBE_SCHEMA = z.object({
  category: z.string().optional().describe("top / bottoms / outerwear / sets / others"),
  tags: z.array(z.string()).optional(),
});

export const answerSchema = z.object({
  blocks: z.array(
    z.object({
      type: z.enum(["text", "product", "wardrobe"]).describe("text、product 或 wardrobe"),
      text: z.string().optional().describe("type=text 時的文字內容"),
      id: z.string().optional().describe(
        "type=product 時為 search_products 回傳的商品 id；type=wardrobe 時為 search_wardrobe 回傳的衣櫃單品 id",
      ),
    }),
  ),
});

export function buildTools(deps: {
  admin: SupabaseClient;
  userId: string;
  categoryIdByName: Map<string, string>;
}) {
  const { admin, userId, categoryIdByName } = deps;
  return {
    search_products: tool({
      description:
        "搜尋商店真實上架商品。需要具體單品時呼叫；回傳的 id 之後用於最終回覆的 product block。除 query 與 category_name 外，其餘屬性參數皆為選填，只有當使用者明確提到該條件時才填，否則留空以免過度篩選而找不到商品。",
      inputSchema: SEARCH_PRODUCTS_SCHEMA,
      execute: (args) => runSearchProducts(admin, args, categoryIdByName),
    }),
    search_wardrobe: tool({
      description: "搜尋使用者衣櫃既有衣物；想用既有單品搭配時優先呼叫。",
      inputSchema: SEARCH_WARDROBE_SCHEMA,
      execute: async (args) => ({
        items: await runSearchWardrobe(admin, userId, args),
      }),
    }),
  };
}
