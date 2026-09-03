import { generateObject, jsonSchema } from "npm:ai@^6.0.208";
import { vertexModel } from "./vertex/provider.ts";
import { chatModel } from "./vertex/config.ts";

export async function analyzeAudio<T extends Record<string, unknown> = Record<string, unknown>>(
  { audioBase64, mimeType, prompt, schema }: {
    audioBase64: string;
    mimeType: string;
    prompt: string;
    schema: Record<string, unknown>;
  },
): Promise<T> {
  const { object } = await generateObject({
    model: vertexModel(chatModel()),
    schema: jsonSchema<T>(schema),
    messages: [
      {
        role: "user",
        content: [
          { type: "text", text: prompt },
          { type: "file", mediaType: mimeType, data: audioBase64 },
        ],
      },
    ],
  });
  return object;
}
