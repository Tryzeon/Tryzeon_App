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
    const { userRequirement, gender } = JSON.parse(bodyText);

    if (!userRequirement || userRequirement.trim() === "") {
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

    // Process LLM Request
    const prompt = `你是穿搭顧問。根據使用者需求，推薦一整套穿搭。

【可用商品分類清單】（請只從這個清單選 category_name，必須一字不差）
${categoryLines}

【使用者需求】
${userRequirement}

請只回傳純 JSON（不要 markdown code fence），格式：
{
  "description": "整體穿搭說明（2-3 句中文）",
  "slots": [
    {
      "slot_label": "上衣",
      "category_name": "（從上方清單選一個）",
      "tags": ["白色", "棉"],
      "reason": "一句話說明為何推薦"
    }
  ]
}

規則：
- slots 1-5 個（涵蓋上衣、下身、鞋、配件等）
- 每個 slot 的 tags 2-3 個，挑最關鍵的特徵（顏色 / 品項 / 材質），中文且避免罕見詞
- category_name 必須一字不差地從清單選；找不到合適的就略過該 slot`;

    const result = await getAIClient().models.generateContent({
      model: VERTEX_CONFIG.CHAT_MODEL!,
      contents: prompt,
    });
    const recommendation = result.text ?? "";

    // Try-parse JSON. On any failure, fall back to description-only.
    let description = "";
    let slots: unknown[] = [];
    try {
      // Strip code fences if model wrapped output anyway.
      const cleaned = recommendation
        .trim()
        .replace(/^﻿/, "")
        .replace(/^```(?:json)?\s*/i, "")
        .replace(/\s*```$/i, "");
      const parsed = JSON.parse(cleaned);
      description = typeof parsed.description === "string" ? parsed.description : "";
      slots = Array.isArray(parsed.slots) ? parsed.slots : [];
    } catch (e) {
      console.warn("LLM returned non-JSON; falling back to text:", e);
      description = recommendation;
      slots = [];
    }

    // Return Success Response
    return new Response(JSON.stringify({ description, slots, usage }), {
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
