import { generateObject, jsonSchema } from "npm:ai@^6.0.208";
import { vertexModel } from "./vertex/provider.ts";
import { chatModel } from "./vertex/config.ts";

/**
 * Runs a single-recording structured-output analysis and returns the parsed
 * object. Raises when the model returns nothing matching `schema`, for the same
 * reason `analyzeImage` does.
 *
 * Takes `mimeType` where the image helper detects one: an audio container is
 * whatever the recorder produced, and the caller is the only party that knows.
 */
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
