import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { GoogleGenerativeAI } from "npm:@google/generative-ai";

class UserError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "UserError";
  }
}

Deno.serve(async (req) => {
  try {
    const genAI = new GoogleGenerativeAI(Deno.env.get("API_KEY"));
    const LLM_Model = "gemini-2.5-flash";

    const { userRequirement } = await req.json();

    if (!userRequirement || userRequirement.trim() === "") {
      throw new UserError("請提供穿搭需求");
    }

    var prompt = `請根據以下穿搭需求，提供具體的服裝搭配建議，包括上衣、下身、鞋子和配件的推薦，簡短一點即可，但要分段說明。
  ${userRequirement}`;

    const model = genAI.getGenerativeModel({
      model: LLM_Model
    });

    const result = await model.generateContent(prompt);
    const text = result.response.text();

    return new Response(JSON.stringify({
      text
    }), {
      headers: {
        "Content-Type": "application/json"
      }
    });
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
