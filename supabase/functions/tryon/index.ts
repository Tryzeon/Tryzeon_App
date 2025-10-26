// Setup type definitions for built-in Supabase Runtime APIs
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { GoogleGenerativeAI } from "npm:@google/generative-ai";
import { createClient } from "jsr:@supabase/supabase-js@2";

const genAI = new GoogleGenerativeAI(Deno.env.get("API_KEY"));

Deno.serve(async (req) => {
  try {
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

    // 取得使用者
    const { data: { user }, error: userError } = await supabase.auth.getUser();
    if (userError || !user) throw new Error("User not found");

    // ========== Rate Limiting Logic with Subscription Plans ==========
    // Define limits for each plan
    const PLAN_LIMITS = {
      free: 5,
      pro: 50,
      ultra: 1000,
    };

    const today = new Date().toISOString().split('T')[0]; // YYYY-MM-DD

    // Get user's subscription info
    const { data: subscribeData, error: subscribeError } = await supabase
      .from('subscribe')
      .select('plan, daily_usage_count, last_reset_date')
      .eq('user_id', user.id)
      .single();

    if (subscribeError || !subscribeData) {
      console.error('Error fetching subscription:', subscribeError);
      throw new Error('User subscription not found. Please contact support.');
    }

    const userPlan = subscribeData.plan;
    const dailyLimit = PLAN_LIMITS[userPlan as keyof typeof PLAN_LIMITS];
    let currentUsage = subscribeData.daily_usage_count;
    const lastResetDate = subscribeData.last_reset_date;

    // Reset counter if it's a new day
    if (lastResetDate !== today) {
      currentUsage = 0;
      await supabase
        .from('subscribe')
        .update({
          daily_usage_count: 0,
          last_reset_date: today,
        })
        .eq('user_id', user.id);
    }

    // Check if limit exceeded
    if (currentUsage >= dailyLimit) {
      return new Response(
        JSON.stringify({
          error: '今日試穿次數已達上限，請明天再試或升級方案',
        }),
        {
          status: 429,
          headers: {
            'Content-Type': 'application/json',
          },
        }
      );
    }

    // Increment usage count
    await supabase
      .from('subscribe')
      .update({ daily_usage_count: currentUsage + 1 })
      .eq('user_id', user.id);
    // ========== End Rate Limiting ==========

    // 從請求中取得可能的圖像欄位
    const body = await req.json();
    const { avatar_image, clothing_image, product_image_url } = body;

    // 處理 avatar 圖片：優先使用傳入的 base64，否則從 storage 下載
    let avatarBase64: string;
    if (avatar_image) {
      // 使用傳入的 avatar base64
      avatarBase64 = avatar_image;
      console.log("Using provided avatar image (base64)");
    } else {
      // 從 storage 下載 avatar
      console.log("Downloading avatar from storage");
      const { data: files, error: listError } = await supabase.storage
        .from("avatars")
        .list(`${user.id}/avatar`);
      if (listError) throw listError;
      if (!files || files.length === 0) throw new Error("No avatar found");

      const fileName = `${user.id}/avatar/${files[0].name}`;
      const { data: avatarData, error: downloadError } = await supabase.storage
        .from("avatars")
        .download(fileName);
      if (downloadError) throw downloadError;

      // 轉成 Base64
      const buf = new Uint8Array(await avatarData.arrayBuffer());
      avatarBase64 = btoa(
        Array.from(buf, (b) => String.fromCharCode(b)).join("")
      );
      console.log("Avatar downloaded successfully");
    }

    let secondImageBase64 = null;
    let secondImageMime = "image/png";

    if (clothing_image) {
      // 若有 clothing_image (直接是 Base64)
      secondImageBase64 = clothing_image;
      secondImageMime = "image/png"; // 若你知道是 PNG，可以保留；若可能為 JPEG，可做判別
    } else {
      // 若無 clothing_image，但有 product_image_url → 下載
      console.log("Product image URL:", product_image_url);
      const productImageResponse = await fetch(product_image_url);
      if (!productImageResponse.ok) {
        throw new Error(
          `Failed to download product image: ${productImageResponse.statusText}`
        );
      }

      const productImageBuffer = await productImageResponse.arrayBuffer();
      const productImageBytes = new Uint8Array(productImageBuffer);
      secondImageBase64 = btoa(
        Array.from(productImageBytes, (b) => String.fromCharCode(b)).join("")
      );
      secondImageMime = productImageResponse.headers.get("content-type") ?? "image/png";
      console.log("Product image downloaded successfully");
    } 

    // 設定 model
    const model = genAI.getGenerativeModel({
      model: "models/gemini-2.5-flash-image",
      generationConfig: {
        responseModalities: ["TEXT", "IMAGE"],
        imageConfig: {
          aspect_ratio: "9:16"
        }
      },
    });

    // retry 最多 3 次
    let generatedImageBase64 = null;
    const MAX_RETRIES = 3;

    for (let attempt = 1; attempt <= MAX_RETRIES; attempt++) {
      const result = await model.generateContent([
        {
          text: "請將第一張照片中的人換上第二張照片中的服裝，保持人物臉部清晰、姿勢自然，生成完整的合成圖。輸出為直式 9 : 16 比例。",
        },
        {
          inlineData: {
            data: avatarBase64,
            mimeType: "image/jpeg",
          },
        },
        {
          inlineData: {
            data: secondImageBase64,
            mimeType: secondImageMime,
          },
        },
      ]);

      const candidates = result.response.candidates ?? [];
      for (const c of candidates) {
        for (const p of c.content.parts ?? []) {
          if (p.inlineData?.mimeType?.startsWith("image/")) {
            generatedImageBase64 = p.inlineData.data;
            break;
          }
        }
        if (generatedImageBase64) break;
      }

      if (generatedImageBase64) break;

      console.warn(`⚠️ Gemini failed to return image (attempt ${attempt})`);
      await new Promise((r) => setTimeout(r, 1000));
    }

    if (!generatedImageBase64) {
      console.warn("🚨 Gemini failed after 3 retries. Using original avatar.");
      generatedImageBase64 = avatarBase64;
    }

    return new Response(
      JSON.stringify({
        image: `data:image/png;base64,${generatedImageBase64}`,
      }),
      {
        headers: {
          "Content-Type": "application/json",
        },
      }
    );
  } catch (err) {
    console.error(err);
    return new Response(
      JSON.stringify({
        error: "伺服器發生錯誤，請稍後再試。",
      }),
      {
        status: 500,
        headers: {
          "Content-Type": "application/json",
        },
      }
    );
  }
});

