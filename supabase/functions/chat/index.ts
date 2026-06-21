// default model: gemini-2.5-flash
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { streamText, stepCountIs } from "npm:ai@^6.0.208";
import { createVertex } from "npm:@ai-sdk/google-vertex@^4.0.147/edge";
import { getAuthenticatedUserClient, getAdminClient } from "../_shared/supabase.ts";
import { QuotaManager } from "../_shared/quota.ts";
import { buildTools } from "./tools.ts";
import {
  assembleAnswerBlocks,
  type ChatMessage,
  type ContentBlock,
  nonEmptyStr,
  parseAnswerRefs,
  PRODUCT_SELECT,
  toModelMessages,
  WARDROBE_SELECT,
} from "./logic.ts";
import { encodeEvent } from "./stream.ts";

const FALLBACK_TEXT = "抱歉，我這次沒能幫你找到，可以再多說一點你的需求嗎？";
const CHAT_MODEL = Deno.env.get("CHAT_MODEL") ?? "gemini-2.5-flash";

// Vertex provider, authenticated with the service account. The edge variant signs
// the SA JWT via Web Crypto. We pass credentials explicitly so we can un-escape
// the private key: the provider strips whitespace but not literal "\n", and keys
// copied from the JSON key file carry escaped newlines that otherwise break atob.
const vertex = createVertex({
  project: Deno.env.get("GOOGLE_VERTEX_PROJECT"),
  location: Deno.env.get("GOOGLE_VERTEX_LOCATION") ?? "us-central1",
  googleCredentials: {
    clientEmail: Deno.env.get("GOOGLE_CLIENT_EMAIL") ?? "",
    privateKey: (Deno.env.get("GOOGLE_PRIVATE_KEY") ?? "").replace(/\\n/g, "\n"),
    privateKeyId: Deno.env.get("GOOGLE_PRIVATE_KEY_ID"),
  },
});

// Fetch the rows the model referenced in respond(), keyed by id, by running the
// caller's prepared query with an `.in("id", ids)` filter. Empty ids → empty map
// (no query); missing ids (e.g. a since-deleted item) are simply absent.
async function fetchRowsByIds(
  // deno-lint-ignore no-explicit-any
  query: any,
  ids: string[],
): Promise<Map<string, Record<string, any>>> {
  const map = new Map<string, Record<string, any>>();
  if (ids.length === 0) return map;
  const { data, error } = await query.in("id", ids);
  if (error) throw error;
  for (const row of data ?? []) map.set(String(row.id), row);
  return map;
}

// Maps the stored age_range bucket codes to human labels for the AI prompt.
const AGE_RANGE_LABELS: Record<string, string> = {
  under_12: "12 歲以下",
  "13_17": "13–17 歲",
  "18_24": "18–24 歲",
  "25_34": "25–34 歲",
  "35_54": "35–54 歲",
  "55_plus": "55 歲以上",
};

Deno.serve(async (req) => {
  let quotaManager: QuotaManager | undefined;

  try {
    // Auth: Verify JWT and get user securely
    const { userClient, user, errorResponse } = await getAuthenticatedUserClient(req);
    if (errorResponse) return errorResponse;

    const bodyText = await req.text();
    if (!bodyText) {
      return new Response(
        JSON.stringify({ error: "Empty request body", code: "BAD_REQUEST" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }
    const { messages } = JSON.parse(bodyText);

    if (!Array.isArray(messages) || messages.length === 0) {
      return new Response(
        JSON.stringify({ error: "Missing required fields", code: "VALIDATION_ERROR" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    const adminClient = getAdminClient();
    quotaManager = new QuotaManager(adminClient, user!.id, "chat");

    const { allowed, usage } = await quotaManager.incrementQuota();
    if (!allowed) {
      return new Response(
        JSON.stringify({
          error: "Rate limit exceeded",
          code: "RATE_LIMIT_EXCEEDED",
          usage: usage,
        }),
        { status: 429, headers: { "Content-Type": "application/json" } }
      );
    }

    const [{ data: profile }, { data: categories, error: catErr }] = await Promise.all([
      adminClient
        .from("user_profiles")
        .select("name, gender, age_range, style_preferences")
        .eq("user_id", user!.id)
        .maybeSingle(),
      adminClient.from("product_categories").select("id, name"),
    ]);

    if (catErr) {
      console.error("Failed to fetch product_categories:", catErr);
      await quotaManager?.rollbackQuota();
      return new Response(
        JSON.stringify({ error: "Internal server error", code: "INTERNAL_ERROR" }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      );
    }

    const userName = nonEmptyStr(profile?.name);
    const userGender = nonEmptyStr(profile?.gender);
    const userAge = AGE_RANGE_LABELS[nonEmptyStr(profile?.age_range) ?? ""] ?? null;
    const userStyles = Array.isArray(profile?.style_preferences)
      ? (profile.style_preferences as string[])
      : [];

    const categoryIdsByName = new Map<string, string[]>();
    for (const c of categories ?? []) {
      const ids = categoryIdsByName.get(c.name) ?? [];
      ids.push(c.id);
      categoryIdsByName.set(c.name, ids);
    }

    const categoryLines = (categories ?? []).map((c) => `- ${c.name}`).join("\n");

    const userContextLines = [
      `- 姓名：${userName ?? "未提供"}`,
      `- 性別：${userGender ?? "未提供"}`,
      `- 年齡：${userAge ?? "未提供"}`,
      `- 偏好風格：${userStyles.length > 0 ? userStyles.join("、") : "未提供"}`,
    ].join("\n");

    const systemInstruction = `你是「Tryzeon 時尚助理」，Tryzeon App 的專屬 AI 穿搭與購物顧問，親切而專業，正在和使用者對話。
當使用者問你是誰、你叫什麼，或向你打招呼自我介紹時，表明「我是 Tryzeon 時尚助理」，並簡短說明你能幫忙找單品、用衣櫃既有衣物配整套穿搭。平常對話不需要主動反覆強調這個身分。
你有兩個搜尋工具：search_wardrobe（使用者衣櫃既有衣物）、search_products（商店真實商品）。
判斷意圖再決定搜哪裡：
- 使用者想「找 / 買某件單品」時，直接 search_products。
- 使用者想「幫我配一套 / 用我現有的搭」時，先 search_wardrobe，缺的品類再 search_products。
輸出（務必遵守）：
- 需求不清楚時，用 respond 送出一個 text 區塊友善追問，不要呼叫搜尋工具。
- 有結果時，用 respond 送出「有序」的 blocks：text（說明）、product（商店商品，用 search_products 回傳的 id）、wardrobe（衣櫃單品，用 search_wardrobe 回傳的 id）。
- 推薦任何一件衣服或單品時，一律用 product 或 wardrobe 區塊承載，由 id 對應真實商品才能在畫面上渲染成商品卡。
- 嚴禁在 text 區塊裡寫出商品 id，或用純文字描述某件具體商品來「假裝推薦」——這樣不會被渲染成卡片。text 區塊只用於說明、過場與追問，絕不放任何商品 id 或當作推薦單品的載體。
- 一個 product/wardrobe 區塊只放一件；要推薦多件就放多個。
- 整套穿搭：用「text 描述部位（如：上身…）→ 該部位的 product 或 wardrobe」交錯排列。
- 搜尋可能回 0 筆。某條件找不到時，放寬條件（移除精確過濾或簡化 query）再搜一次；仍找不到就用 text 說明並追問。
- 商店單品用 product、衣櫃單品用 wardrobe，type 與 id 來源要對應；嚴禁編造 id。每一回合都必須有輸出，絕不空白。
- 一定要用 respond 工具送出最終回覆，不要只回純文字。

【使用者資訊】（推薦時可參考；是否套用到搜尋條件由你自行判斷，不強制。例如可視情況把性別或偏好風格帶入 search_products 的 gender / styles 參數）
${userContextLines}

【可用商品分類清單】（search_products 的 category_name 請從這裡選）
${categoryLines}`;

    // The AI SDK runs the agent loop: search_* tools have `execute` so it calls
    // them and re-prompts automatically (capped by stopWhen); `respond` has no
    // `execute`, so the loop halts and hands its call back to us as the answer.
    const tools = buildTools({ adminClient, userId: user!.id, categoryIdsByName });

    const stream = new ReadableStream({
      async start(controller) {
        const send = (ev: Record<string, unknown>) => controller.enqueue(encodeEvent(ev));
        try {
          const result = streamText({
            model: vertex(CHAT_MODEL),
            system: systemInstruction,
            messages: toModelMessages(messages as ChatMessage[]),
            tools,
            stopWhen: stepCountIs(10),
          });

          // Forward each search as it happens. `respond` is the answer carrier,
          // not a progress step, so it is not emitted here.
          for await (const part of result.fullStream) {
            if (part.type === "tool-call" && part.toolName !== "respond") {
              send({ type: "tool_use", id: part.toolCallId, name: part.toolName, input: part.input });
            } else if (part.type === "tool-result") {
              send({ type: "tool_result", tool_use_id: part.toolCallId, content: part.output });
            }
          }

          const toolCalls = await result.toolCalls;
          const respondCall = toolCalls.find((tc) => tc.toolName === "respond");
          let answerBlocks: ContentBlock[];
          if (respondCall) {
            const refs = parseAnswerRefs(respondCall.input as Record<string, any>);
            const [products, wardrobe] = await Promise.all([
              fetchRowsByIds(
                adminClient.from("products").select(PRODUCT_SELECT),
                refs.filter((r) => r.type === "product").map((r) => r.id),
              ),
              fetchRowsByIds(
                adminClient.from("wardrobe_items").select(WARDROBE_SELECT).eq("user_id", user!.id),
                refs.filter((r) => r.type === "wardrobe").map((r) => r.id),
              ),
            ]);
            answerBlocks = assembleAnswerBlocks(refs, products, wardrobe);
          } else {
            const text = ((await result.text) ?? "").trim();
            answerBlocks = text ? [{ type: "text", text }] : [];
          }
          if (answerBlocks.length === 0) {
            answerBlocks = [{ type: "text", text: FALLBACK_TEXT }];
          }

          send({
            type: "done",
            message: { role: "assistant", content: answerBlocks },
            usage,
          });
        } catch (err) {
          console.error("Chat stream error:", err);
          await quotaManager?.rollbackQuota();
          send({ type: "error", code: "INTERNAL_ERROR" });
        } finally {
          controller.close();
        }
      },
    });

    return new Response(stream, {
      headers: {
        "Content-Type": "application/x-ndjson",
        "Cache-Control": "no-cache",
      },
    });

  } catch (err) {
    console.error("Unexpected error:", err);

    await quotaManager?.rollbackQuota();

    return new Response(
      JSON.stringify({ error: "Internal server error", code: "INTERNAL_ERROR" }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
