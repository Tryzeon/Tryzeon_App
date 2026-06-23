import { GoogleGenAI } from "npm:@google/genai";
import { getAIClient, VERTEX_CONFIG } from "./vertex-ai.ts";

export async function analyzeAudio<T extends Record<string, unknown> = Record<string, unknown>>(
  { audioBase64, mimeType, prompt, schema }: {
    audioBase64: string;
    mimeType: string;
    prompt: string;
    schema: Record<string, unknown>;
  },
): Promise<T> {
  const ai: GoogleGenAI = getAIClient();
  const result = await ai.models.generateContent({
    model: VERTEX_CONFIG.CHAT_MODEL!,
    contents: [
      {
        role: "user",
        parts: [
          { text: prompt },
          { inlineData: { mimeType, data: audioBase64 } },
        ],
      },
    ],
    config: {
      responseMimeType: "application/json",
      responseSchema: schema,
    },
  });
  try {
    const parsed = JSON.parse(result.text ?? "{}");
    return (parsed && typeof parsed === "object") ? parsed as T : {} as T;
  } catch {
    return {} as T;
  }
}
