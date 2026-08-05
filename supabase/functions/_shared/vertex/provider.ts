/**
 * The AI SDK provider every Vertex call in this project goes through — the chat
 * agent's loop, the one-shot analysis helpers, and try-on's image and video
 * generation.
 *
 * One provider rather than one per feature: they authenticate as the same
 * service account, reach the same project and location, and differ only in what
 * they ask the model for.
 *
 * Built on first use and kept for the isolate, deliberately not at import:
 * `chat/run.ts` names its Vertex runner as the default, so anything touching
 * the chat core pulls this module in — including callers that always inject
 * their own runner, and tests that never reach the network. Building at import
 * would make Vertex credentials a requirement for all of them.
 */
import { createVertex } from "npm:@ai-sdk/google-vertex@^4.0.147/edge";
import { VERTEX_LOCATION, vertexProject, vertexServiceAccount } from "./config.ts";

let provider: ReturnType<typeof createVertex> | null = null;

/**
 * The provider itself. The edge variant signs the service-account JWT via Web
 * Crypto, so project and location must be named — unlike express mode, where
 * the key implied both. It resolves `fetch` per request rather than capturing
 * it here, which is what lets a test observe the call.
 */
function vertexProvider() {
  return provider ??= createVertex({
    project: vertexProject(),
    location: VERTEX_LOCATION,
    googleCredentials: vertexServiceAccount(),
  });
}

/** A language-model handle for `generateObject` / `generateText` / `streamText`. */
export function vertexModel(modelId: string) {
  return vertexProvider()(modelId);
}

/** A video-model handle for `experimental_generateVideo`, which owns Veo's polling. */
export function vertexVideoModel(modelId: string) {
  return vertexProvider().videoModel(modelId);
}
