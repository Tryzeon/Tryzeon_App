import { GoogleGenAI } from "npm:@google/genai";

export const VERTEX_CONFIG = {
  CHAT_MODEL: Deno.env.get("CHAT_MODEL"),
};

let _aiClient: GoogleGenAI | null = null;

export function getAIClient(): GoogleGenAI {
  if (!_aiClient) {
    const apiKey = Deno.env.get("VERTEX_API_KEY");

    if (!apiKey) {
      throw new Error("VERTEX_API_KEY environment variable is required");
    }

    // Vertex AI express mode: authenticate with the API key alone. Passing
    // project/location alongside apiKey is rejected by @google/genai
    // ("Project/location and API key are mutually exclusive").
    _aiClient = new GoogleGenAI({
      vertexai: true,
      apiKey: apiKey,
    });
  }

  return _aiClient;
}
