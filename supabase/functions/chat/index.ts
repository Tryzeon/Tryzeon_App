// Setup type definitions for built-in Supabase Runtime APIs
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { GoogleGenerativeAI } from "npm:@google/generative-ai";
// 初始化 Gemini 客戶端
const genAI = new GoogleGenerativeAI(Deno.env.get("API_KEY"));
Deno.serve(async (req)=>{
  const { prompt } = await req.json();
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
