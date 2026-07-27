/**
 * The AI SDK provider every Vertex language-model call in this project goes
 * through — the chat agent's loop and the one-shot analysis helpers alike.
 *
 * One provider rather than one per feature: they authenticate with the same
 * key, reach the same express-mode endpoint, and differ only in what they ask
 * the model for. Try-on stays outside this module and calls Vertex REST by
 * hand, because Veo's long-running operation polling is not something the SDK
 * wraps.
 *
 * Built on first use and kept for the isolate, deliberately not at import:
 * `chat/run.ts` names its Vertex runner as the default, so anything touching
 * the chat core pulls this module in — including callers that always inject
 * their own runner, and tests that never reach the network. Building at import
 * would make a Vertex API key a requirement for all of them.
 */
import { createVertex } from "npm:@ai-sdk/google-vertex@^4.0.147/edge";
import { vertexApiKey } from "./config.ts";

let provider: ReturnType<typeof createVertex> | null = null;

/**
 * A model handle for `generateObject` / `streamText`.
 *
 * Express mode: the API key alone authenticates and identifies the project, so
 * neither project nor location is passed. The SDK resolves `fetch` per request
 * rather than capturing it here, which is what lets a test observe the call.
 */
export function vertexModel(modelId: string) {
  provider ??= createVertex({ apiKey: vertexApiKey() });
  return provider(modelId);
}
