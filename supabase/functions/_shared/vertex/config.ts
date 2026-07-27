/**
 * Every Vertex AI setting the edge functions read, in one place.
 *
 * Every call site reads its credential and its model name from here, and every
 * language-model call goes through the one AI SDK provider in `provider.ts` —
 * chat's agent loop and the one-shot analysis helpers alike, since they differ
 * only in what they ask the model for. Try-on is the one exception, calling
 * Vertex REST by hand for Gemini's image config and Veo's long-running
 * operation polling, which no SDK wraps well.
 *
 * That uniformity was not the starting point: each call site had picked its own
 * credential and its own names for the same project — a deployment had to keep
 * GOOGLE_CLOUD_PROJECT and GOOGLE_VERTEX_PROJECT in agreement with nothing
 * checking, and rotating a key meant finding every reader.
 *
 * Readers are functions rather than constants because they raise when unset,
 * and no consumer needs the whole set: validating everything at import would
 * stop `chat` from booting over a try-on variable, or a wardrobe upload over
 * the chat model. Each caller asks for what it uses and decides when — at its
 * own module load where that is safe, lazily where the module is reachable from
 * code that never calls Vertex at all.
 *
 * ## Environment
 *
 * | Variable                | Required | Read by                              |
 * | ----------------------- | -------- | ------------------------------------ |
 * | `VERTEX_API_KEY`        | yes      | everything — the single credential   |
 * | `GOOGLE_CLOUD_PROJECT`  | yes      | try-on, to build the REST endpoint   |
 * | `GOOGLE_CLOUD_LOCATION` | no       | try-on; defaults to `us-central1`    |
 * | `CHAT_MODEL`            | no       | chat, image analysis, audio analysis |
 * | `TRYON_MODEL`           | yes      | try-on images                        |
 * | `VIDEO_MODEL`           | yes      | try-on video                         |
 *
 * `CHAT_MODEL` naming three unrelated features is a known wart: changing the
 * chat model also changes how wardrobe photos and size recordings are read.
 */

function requireEnv(name: string): string {
  const value = Deno.env.get(name);
  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}

/**
 * The one credential. Express-mode authentication: the key alone identifies the
 * project, which is why only try-on — whose REST URLs name it explicitly — has
 * to know the project id at all.
 */
export const vertexApiKey = (): string => requireEnv("VERTEX_API_KEY");

/** GCP project id, for callers that build Vertex REST URLs by hand. */
export const vertexProject = (): string => requireEnv("GOOGLE_CLOUD_PROJECT");

/** Vertex region. Has a default, so it never fails. */
export const VERTEX_LOCATION = Deno.env.get("GOOGLE_CLOUD_LOCATION") ??
  "us-central1";

/** Model behind the chat agent and both analysis helpers. */
export const chatModel = (): string => requireEnv("CHAT_MODEL");

/** Model behind try-on image generation. */
export const tryonImageModel = (): string => requireEnv("TRYON_MODEL");

/** Model behind try-on video generation. No sensible default to fall back on. */
export const tryonVideoModel = (): string => requireEnv("VIDEO_MODEL");
