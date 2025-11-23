import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { GoogleGenerativeAI } from "npm:@google/generative-ai";
import { createClient } from "jsr:@supabase/supabase-js@2";

class UserError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "UserError";
  }
}

Deno.serve(async (req) => {
  try {
    const genAI = new GoogleGenerativeAI(Deno.env.get("API_KEY"));
    const LLM_MODEL = "models/gemini-2.5-flash-image";

    const PLAN_LIMITS = {
      free: 5,
      pro: 50,
      ultra: 1000
    };

    const authHeader = req.headers.get("Authorization");
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL"),
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY"),
      {
        global: {
          headers: {
            Authorization: authHeader ?? "",
          },
        },
      }
    );

    const { data: { user }, error: userError } = await supabase.auth.getUser();
    if (userError) throw userError;

    const { data: subscribeData, error: subscribeError } = await supabase
      .from('subscribe')
      .select('plan, daily_usage_count, last_reset_date')
      .eq('user_id', user.id)
      .single();
    if (subscribeError) throw subscribeError;

    const userPlan = subscribeData.plan;
    const dailyLimit = PLAN_LIMITS[userPlan];

    const lastResetDate = subscribeData.last_reset_date;
    const today = new Date().toISOString().split('T')[0];

    let currentUsage = subscribeData.daily_usage_count;

    if (lastResetDate !== today) currentUsage = 0;

    if (currentUsage >= dailyLimit) throw new UserError('今日試穿次數已達上限，請明天再試或升級方案');

    const { error: updateError } = await supabase
      .from('subscribe')
      .update({
        daily_usage_count: currentUsage + 1,
        last_reset_date: today,
      })
      .eq('user_id', user.id);
    if (updateError) throw updateError;

    const body = await req.json();
    const { avatar_image, clothing_image, product_image_url } = body;

    let avatarBase64;
    if (avatar_image) {
      avatarBase64 = avatar_image;
    } else {
      const { data: files, error: listError } = await supabase.storage
        .from("avatars")
        .list(`${user.id}/avatar`);

      if (listError) throw listError;
      if (!files || files.length == 0) throw new Error("No avatar found");

      const fileName = `${user.id}/avatar/${files[0].name}`;
      const { data: avatarData, error: downloadError } = await supabase.storage.from("avatars").download(fileName);
      if (downloadError) throw downloadError;

      const buf = new Uint8Array(await avatarData.arrayBuffer());
      avatarBase64 = btoa(Array.from(buf, (b) => String.fromCharCode(b)).join(""));
    }

    let ClothingBase64 = null;
    if (clothing_image) {
      ClothingBase64 = clothing_image;
    } else if (product_image_url) {
      let bucket;
      if (product_image_url.includes('wardrobe')) {
        bucket = 'wardrobe';
      } else if (product_image_url.includes('product')) {
        bucket = 'store';
      } else {
        throw new Error(`Cannot determine bucket from path: ${product_image_url}`);
      }

      const { data: clothingData, error: downloadError } = await supabase.storage.from(bucket).download(product_image_url);
      if (downloadError) throw downloadError;

      const buf = new Uint8Array(await clothingData.arrayBuffer());
      ClothingBase64 = btoa(Array.from(buf, (b) => String.fromCharCode(b)).join(""));
    }

    const model = genAI.getGenerativeModel({
      model: LLM_MODEL,
      generationConfig: {
        responseModalities: [
          "TEXT",
          "IMAGE"
        ],
        imageConfig: {
          aspect_ratio: "9:16"
        }
      }
    });

    const MAX_RETRIES = 3;
    for (let attempt = 1; attempt <= MAX_RETRIES; attempt++) {
      const result = await model.generateContent([
        {
          text: "請將第一張照片中的人換上第二張照片中的服裝，保持人物臉部清晰、姿勢自然，生成完整的合成圖。輸出為直式 9 : 16 比例。"
        },
        {
          inlineData: {
            data: avatarBase64,
            mimeType: "image/jpeg"
          }
        },
        {
          inlineData: {
            data: ClothingBase64,
            mimeType: "image/jpeg"
          }
        }
      ]);

      const candidates = result.response.candidates ?? [];
      for (const c of candidates) {
        for (const p of c.content.parts ?? []) {
          if (p.inlineData?.mimeType?.startsWith("image/")) {
            const resultImageBase64 = p.inlineData.data;

            return new Response(JSON.stringify({
              image: `data:image/png;base64,${resultImageBase64}`
            }), {
              headers: {
                "Content-Type": "application/json"
              }
            });
          }
        }
      }
      await new Promise((r) => setTimeout(r, 1000));
    }
    throw new UserError("無法辨識圖像，請更換其他張試試！");
  } catch (err) {
    let errorMessage;
    if (err instanceof UserError) {
      errorMessage = err.message;
    } else {
      console.error(err);
      errorMessage = "伺服器發生錯誤，請稍後再試。";
    }

    return new Response(JSON.stringify({
      message: errorMessage
    }), {
      status: 500,
      headers: {
        "Content-Type": "application/json"
      }
    });
  }
});