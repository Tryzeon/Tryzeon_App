import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { GoogleGenerativeAI, GenerativeModel } from "npm:@google/generative-ai";
import { createClient, SupabaseClient } from "jsr:@supabase/supabase-js@2";

// --- Configuration & Constants ---
const CONFIG = {
  GEMINI_API_KEY: Deno.env.get("GEMINI_API_KEY"),
  SUPABASE_URL: Deno.env.get("SUPABASE_URL"),
  SUPABASE_SERVICE_ROLE_KEY: Deno.env.get("SUPABASE_SERVICE_ROLE_KEY"),
  MODEL_NAME: "models/gemini-2.5-flash-image",
  MAX_RETRIES: 3,
  RETRY_DELAY_MS: 1000,
};

const PLAN_LIMITS: Record<string, number> = {
  free: 5,
  pro: 50,
  ultra: 1000,
};

// --- Types & Interfaces ---
interface TryOnRequest {
  avatarBase64?: string;
  avatarPath?: string;
  clothesBase64?: string;
  clothesPath?: string;
}

interface TryOnResponse {
  image: string; // Base64 data URI
}

interface SubscriptionData {
  plan: string;
  daily_usage_count: number;
  last_reset_date: string | null;
}

// --- Error Handling ---
class AppError extends Error {
  constructor(public message: string, public statusCode: number = 500) {
    super(message);
    this.name = "AppError";
  }
}

// --- Services ---

class StorageService {
  constructor(private supabase: SupabaseClient) { }

  async fetchImage(path: string): Promise<string> {
    let bucket: string;
    if (path.includes('wardrobe')) {
      bucket = 'wardrobe';
    } else if (path.includes('product')) {
      bucket = 'store';
    } else if (path.includes('avatar')) {
      bucket = 'avatars';
    } else {
      throw new AppError(`Cannot determine bucket from path: ${path}`, 400);
    }

    const { data, error } = await this.supabase.storage.from(bucket).download(path);
    if (error) throw new AppError(`Failed to download image from ${bucket}/${path}: ${error.message}`, 500);

    const buf = new Uint8Array(await data.arrayBuffer());
    return btoa(Array.from(buf, (b) => String.fromCharCode(b)).join(""));
  }
}

class SubscriptionService {
  constructor(private supabase: SupabaseClient) { }

  async checkAndIncrementLimit(userId: string): Promise<void> {
    const { data, error } = await this.supabase
      .from('subscribe')
      .select('plan, daily_usage_count, last_reset_date')
      .eq('user_id', userId)
      .single();

    if (error) throw new AppError(`Subscription check failed: ${error.message}`, 500);
    if (!data) throw new AppError("User subscription not found", 404);

    const subData = data as SubscriptionData;
    const dailyLimit = PLAN_LIMITS[subData.plan];
    const today = new Date().toISOString().split('T')[0];

    let currentUsage = subData.daily_usage_count;
    if (subData.last_reset_date !== today) {
      currentUsage = 0;
    }

    if (currentUsage >= dailyLimit) {
      throw new AppError('Daily try-on limit reached. Please try again tomorrow or upgrade your plan.', 403);
    }

    const { error: updateError } = await this.supabase
      .from('subscribe')
      .update({
        daily_usage_count: currentUsage + 1,
        last_reset_date: today,
      })
      .eq('user_id', userId);

    if (updateError) throw new AppError(`Failed to update usage: ${updateError.message}`, 500);
  }
}

class AIService {
  private model: GenerativeModel;

  constructor(apiKey: string, modelName: string) {
    const genAI = new GoogleGenerativeAI(apiKey);
    this.model = genAI.getGenerativeModel({
      model: modelName,
      generationConfig: {
        responseModalities: ["TEXT", "IMAGE"],
        imageConfig: { aspect_ratio: "9:16" }
      }
    });
  }

  async generateTryOn(avatarBase64: string, clothesBase64: string): Promise<string> {
    const prompt = "Please dress the person in the first photo with the clothes from the second photo, keeping the person's face clear and posture natural, generating a complete composite image. Output in a vertical 9:16 aspect ratio.";

    for (let attempt = 1; attempt <= CONFIG.MAX_RETRIES; attempt++) {
      try {
        const result = await this.model.generateContent([
          { text: prompt },
          { inlineData: { data: avatarBase64, mimeType: "image/jpeg" } },
          { inlineData: { data: clothesBase64, mimeType: "image/jpeg" } }
        ]);

        const candidates = result.response.candidates ?? [];
        for (const c of candidates) {
          for (const p of c.content.parts ?? []) {
            if (p.inlineData?.mimeType?.startsWith("image/")) {
              return p.inlineData.data;
            }
          }
        }
      } catch (error) {
        console.warn(`AI Generation attempt ${attempt} failed:`, error);
        if (attempt === CONFIG.MAX_RETRIES) throw error;
        await new Promise((r) => setTimeout(r, CONFIG.RETRY_DELAY_MS));
      }
    }
    throw new AppError("Unable to recognize image, please try another image!", 422);
  }
}

// --- Main Handler ---

Deno.serve(async (req) => {
  try {
    // 1. Init & Auth
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) throw new AppError("Missing Authorization header", 401);

    // Create user client for auth
    const userClient = createClient(
      CONFIG.SUPABASE_URL,
      CONFIG.SUPABASE_SERVICE_ROLE_KEY,
      { global: { headers: { Authorization: authHeader } } }
    );

    // Create admin client for subscription updates (bypasses RLS)
    const adminClient = createClient(
      CONFIG.SUPABASE_URL,
      CONFIG.SUPABASE_SERVICE_ROLE_KEY
    );

    const { data: { user }, error: authError } = await userClient.auth.getUser();
    if (authError || !user) throw new AppError("Unauthorized", 401);

    // 2. Parse Body
    const body = await req.json() as TryOnRequest;
    const { avatarBase64, avatarPath, clothesBase64, clothesPath } = body;

    if (!avatarPath && !avatarBase64) throw new AppError("Avatar image or path not provided", 400);
    if (!clothesPath && !clothesBase64) throw new AppError("Clothes image or path not provided", 400);

    // 3. Check Subscription (use admin client to bypass RLS)
    const subService = new SubscriptionService(adminClient);
    await subService.checkAndIncrementLimit(user.id);

    // 4. Prepare Images (use user client for storage access)
    const storageService = new StorageService(userClient);
    const avatarImage = avatarBase64 ? avatarBase64 : await storageService.fetchImage(avatarPath!);
    const clothesImage = clothesBase64 ? clothesBase64 : await storageService.fetchImage(clothesPath!);

    // 5. Generate Try-on
    const aiService = new AIService(CONFIG.GEMINI_API_KEY, CONFIG.MODEL_NAME);
    const resultImageBase64 = await aiService.generateTryOn(avatarImage, clothesImage);

    // 6. Response
    const response: TryOnResponse = {
      image: `data:image/png;base64,${resultImageBase64}`
    };

    return new Response(JSON.stringify(response), {
      headers: { "Content-Type": "application/json" }
    });

  } catch (err) {
    console.error(err);

    const status = err instanceof AppError ? err.statusCode : 500;
    const message = err instanceof AppError ? err.message : "Internal Server Error";

    return new Response(JSON.stringify({ message }), {
      status,
      headers: { "Content-Type": "application/json" }
    });
  }
});