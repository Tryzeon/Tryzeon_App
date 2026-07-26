import { GoogleGenAI } from "npm:@google/genai";
import { getAIClient } from "./vertex/genai.ts";
import { chatModel } from "./vertex/config.ts";

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
    model: chatModel(),
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
