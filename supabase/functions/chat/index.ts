// default model: gemini-2.5-flash
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { getAuthenticatedUserClient, getAdminClient } from "../_shared/supabase.ts";
import { QuotaManager } from "../_shared/quota.ts";
import { getAIClient, VERTEX_CONFIG } from "../_shared/vertex-ai.ts";

Deno.serve(async (req) => {
  let quotaManager: QuotaManager | undefined;

  try {
    // Auth: Verify JWT and get user securely
    const { userClient, user, errorResponse } = await getAuthenticatedUserClient(req);
    if (errorResponse) return errorResponse;
    
    const adminClient = getAdminClient();

    // Check and Increment Usage Quota via RPC
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

    // Validate Request Body
    const bodyText = await req.text();
    if (!bodyText) {
      return new Response(
        JSON.stringify({ error: "Empty request body", code: "BAD_REQUEST" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }
    const { messages, gender } = JSON.parse(bodyText);

    if (!Array.isArray(messages) || messages.length === 0) {
      await quotaManager?.rollbackQuota();
      return new Response(
        JSON.stringify({ error: "Missing required fields", code: "VALIDATION_ERROR" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    // Fetch product_categories so the LLM can only choose from existing names.
    let categoryQuery = adminClient.from("product_categories").select("name");
    if (gender === "male" || gender === "female") {
      categoryQuery = categoryQuery.in("gender", [gender, "unisex"]);
    }
    const { data: categories, error: catErr } = await categoryQuery;

    if (catErr) {
      console.error("Failed to fetch product_categories:", catErr);
      await quotaManager?.rollbackQuota();
      return new Response(
        JSON.stringify({ error: "Internal server error", code: "INTERNAL_ERROR" }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      );
    }

    const categoryLines = (categories ?? []).map((c) => `- ${c.name}`).join("\n");

    // Render the conversation history for the prompt.
    const transcript = messages
      .filter((m) => m && typeof m.content === "string" && m.content.trim() !== "")
      .map((m) => `${m.role === "user" ? "使用者" : "顧問"}：${m.content}`)
      .join("\n");

    const prompt = `你是親切專業的穿搭顧問，正在和使用者對話。
你可以「追問」以釐清需求，或「推薦」一整套穿搭，或兩者同時。
- 當需求還不清楚（場合、風格、單品等資訊不足）時，用 message 友善地追問，recommendation 設為 null。
- 當資訊足夠時，用 recommendation 給出穿搭，並可在 message 補一句說明。
- 使用者若不滿意而補充需求，請依新需求重新推薦。

【可用商品分類清單】（recommendation 的 category_name 只能一字不差地從這裡選）
${categoryLines}

【對話紀錄】
${transcript}

請只回傳純 JSON（不要 markdown code fence），格式：
{
  "message": "要對使用者說的話（追問或穿搭說明）；不需要就給空字串",
  "recommendation": {
    "slots": [
      {
        "slot_label": "上衣",
        "category_name": "（從上方清單選一個）",
        "tags": ["白色", "棉"],
        "reason": "一句話說明為何推薦"
      }
    ]
  }
}

規則：
- 只追問時 recommendation 設為 null。
- 要推薦時 slots 1-5 個（涵蓋上衣、下身、鞋、配件等）。
- 每個 slot 的 tags 2-3 個，挑最關鍵的特徵（顏色 / 品項 / 材質），中文且避免罕見詞。
- category_name 必須一字不差地從清單選；找不到合適的就略過該 slot。
- message 與 recommendation 至少要有一個有內容。`;

    const result = await getAIClient().models.generateContent({
      model: VERTEX_CONFIG.CHAT_MODEL!,
      contents: prompt,
    });
    const raw = result.text ?? "";

    // Try-parse JSON. On any failure, fall back to message-only (raw text).
    let message = "";
    let recommendation: { slots: unknown[] } | null = null;
    try {
      const cleaned = raw
        .trim()
        .replace(/^﻿/, "")
        .replace(/^```(?:json)?\s*/i, "")
        .replace(/\s*```$/i, "");
      const parsed = JSON.parse(cleaned);
      message = typeof parsed.message === "string" ? parsed.message : "";
      const slots = Array.isArray(parsed?.recommendation?.slots)
        ? parsed.recommendation.slots
        : [];
      recommendation = slots.length > 0 ? { slots } : null;
    } catch (e) {
      console.warn("LLM returned non-JSON; falling back to text:", e);
      message = raw;
      recommendation = null;
    }

    // Return Success Response
    return new Response(JSON.stringify({ message, recommendation, usage }), {
      headers: { "Content-Type": "application/json" }
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
