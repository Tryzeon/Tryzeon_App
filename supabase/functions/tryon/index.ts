import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { GoogleGenerativeAI } from "npm:@google/generative-ai";
import { createClient } from "jsr:@supabase/supabase-js@2";


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

    const body = await req.json();
    const { avatarBase64, avatarPath, clothesBase64, clothesPath } = body;

    if(!avatarPath && !avatarBase64) {
      throw new Error("未提供頭像圖片");
    }

    if (!clothesPath && !clothesBase64) {
      throw new Error("未提供服裝圖片");
    }


    const { data: { user }, error: authError } = await supabase.auth.getUser();
    if (authError) throw authError;

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

    if (currentUsage >= dailyLimit) throw new Error('今日試穿次數已達上限，請明天再試或升級方案');

    const { error: updateError } = await supabase
      .from('subscribe')
      .update({
        daily_usage_count: currentUsage + 1,
        last_reset_date: today,
      })
      .eq('user_id', user.id);
    if (updateError) throw updateError;

    var avatarImage = avatarBase64;
    var clothesImage = clothesBase64;

    if (avatarPath) {
      const { data: avatarData, error: downloadError } = await supabase.storage.from("avatars").download(avatarPath);
      if (downloadError) throw downloadError;

      const buf = new Uint8Array(await avatarData.arrayBuffer());
      avatarImage = btoa(Array.from(buf, (b) => String.fromCharCode(b)).join(""));
    }

    if (clothesPath) {
      let bucket;
      if (clothesPath.includes('wardrobe')) {
        bucket = 'wardrobe';
      } else if (clothesPath.includes('product')) {
        bucket = 'store';
      } else {
        throw new Error(`Cannot determine bucket from path: ${clothesPath}`);
      }

      const { data: clothesData, error: downloadError } = await supabase.storage.from(bucket).download(clothesPath);
      if (downloadError) throw downloadError;

      const buf = new Uint8Array(await clothesData.arrayBuffer());
      clothesImage = btoa(Array.from(buf, (b) => String.fromCharCode(b)).join(""));
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
            data: avatarImage,
            mimeType: "image/jpeg"
          }
        },
        {
          inlineData: {
            data: clothesImage,
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
    throw new Error("無法辨識圖像，請更換其他張試試！");
  } catch (err) {
    console.error(err);
    return new Response(JSON.stringify({
      message: String(err)
    }), {
      status: 500,
      headers: {
        "Content-Type": "application/json"
      }
    });
  }
});