/**
 * The `@google/genai` client, used by the one-shot analysis helpers.
 *
 * Kept apart from the chat agent's provider and from try-on's REST calls on
 * purpose: this SDK states `responseSchema` directly, which is all image and
 * audio analysis need. Configuration comes from `config.ts` — the client is
 * what varies between call sites, not the credential.
 */
import { GoogleGenAI } from "npm:@google/genai";
import { vertexApiKey } from "./config.ts";

let _aiClient: GoogleGenAI | null = null;

export function getAIClient(): GoogleGenAI {
  if (!_aiClient) {
    // Vertex AI express mode: authenticate with the API key alone. Passing
    // project/location alongside apiKey is rejected by @google/genai
    // ("Project/location and API key are mutually exclusive").
    _aiClient = new GoogleGenAI({ vertexai: true, apiKey: vertexApiKey() });
  }

  return _aiClient;
}
