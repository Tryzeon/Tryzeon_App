import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { GoogleGenerativeAI } from "npm:@google/generative-ai";

const genAI = new GoogleGenerativeAI(Deno.env.get("API_KEY"));

Deno.serve(async (req) => {
  const { userRequirement } = await req.json();
  
  var prompt = `請根據以下穿搭需求，提供具體的服裝搭配建議，包括上衣、下身、鞋子和配件的推薦，簡短一點即可，但要分段說明。
  ${userRequirement}`;
  
  const model = genAI.getGenerativeModel({
    model: "gemini-2.5-flash"
  });
  const result = await model.generateContent(prompt);
  const text = result.response.text();

  return new Response(JSON.stringify({
    text
  }), {
    headers: {
      "Content-Type": "application/json",
      "Connection": "keep-alive"
    }
  });
});
