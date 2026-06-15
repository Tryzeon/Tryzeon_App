// default model: gemini-2.5-flash
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { getAuthenticatedUserClient, getAdminClient } from "../_shared/supabase.ts";
import { QuotaManager } from "../_shared/quota.ts";
import { getAIClient, VERTEX_CONFIG } from "../_shared/vertex-ai.ts";
import { Type } from "npm:@google/genai";

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
      await quotaManager?.rollbackQuota();
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

    // Static persona + rules go in the system instruction, separate from the
    // turn-by-turn conversation (proper multi-turn chat format).
    const systemInstruction = `你是親切專業的穿搭顧問，正在和使用者對話。
你可以「追問」以釐清需求，或「推薦」一整套穿搭，或兩者同時。
- 當需求還不清楚（場合、風格、單品等資訊不足）時，用 message 友善地追問，recommendation 設為 null。
- 當資訊足夠時，用 recommendation 給出穿搭，並可在 message 補一句說明。
- 使用者若不滿意而補充需求，請依新需求重新推薦。

【可用商品分類清單】（recommendation 的 category_name 只能一字不差地從這裡選）
${categoryLines}

規則：
- 只追問時 recommendation 設為 null。
- 要推薦時 slots 1-5 個（涵蓋上衣、下身、鞋、配件等）。
- 每個 slot 的 tags 2-3 個，挑最關鍵的特徵（顏色 / 品項 / 材質），中文且避免罕見詞。
- category_name 必須一字不差地從清單選；找不到合適的就略過該 slot。
- message 與 recommendation 至少要有一個有內容。`;

    // Map the conversation history into the SDK's multi-turn format.
    // Gemini roles are 'user' / 'model' (assistant -> model).
    const contents = messages
      .filter((m) => m && typeof m.content === "string" && m.content.trim() !== "")
      .map((m) => ({
        role: m.role === "user" ? "user" : "model",
        parts: [{ text: m.content }],
      }));

    const responseSchema = {
      type: Type.OBJECT,
      properties: {
        message: { type: Type.STRING },
        recommendation: {
          type: Type.OBJECT,
          nullable: true,
          properties: {
            slots: {
              type: Type.ARRAY,
              items: {
                type: Type.OBJECT,
                properties: {
                  slot_label: { type: Type.STRING },
                  category_name: { type: Type.STRING },
                  tags: { type: Type.ARRAY, items: { type: Type.STRING } },
                  reason: { type: Type.STRING },
                },
                required: ["slot_label", "category_name", "reason"],
                propertyOrdering: ["slot_label", "category_name", "tags", "reason"],
              },
            },
          },
          required: ["slots"],
          propertyOrdering: ["slots"],
        },
      },
      required: ["message"],
      propertyOrdering: ["message", "recommendation"],
    };

    const result = await getAIClient().models.generateContent({
      model: VERTEX_CONFIG.CHAT_MODEL!,
      contents,
      config: {
        systemInstruction,
        responseMimeType: "application/json",
        responseSchema,
      },
    });
    const raw = result.text ?? "";

    // With responseSchema the output is valid JSON; still guard defensively.
    let message = "";
    let recommendation: { slots: unknown[] } | null = null;
    try {
      const parsed = JSON.parse(raw);
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
