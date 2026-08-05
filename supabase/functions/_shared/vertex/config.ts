/**
 * Every Vertex AI setting the edge functions read, in one place.
 *
 * Every call site reads its credential and its model name from here, and every
 * Vertex call goes through the one AI SDK provider in `provider.ts` — chat's
 * agent loop, the one-shot analysis helpers and try-on alike, since they differ
 * only in what they ask the model for.
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
 * | Variable                 | Required | Read by                              |
 * | ------------------------ | -------- | ------------------------------------ |
 * | `GOOGLE_CLIENT_EMAIL`    | yes      | everything — the single credential   |
 * | `GOOGLE_PRIVATE_KEY`     | yes      | everything — the single credential   |
 * | `GOOGLE_PRIVATE_KEY_ID`  | no       | everything; names the signing key    |
 * | `GOOGLE_CLOUD_PROJECT`   | yes      | every Vertex call, to name the project |
 * | `CHAT_MODEL`             | yes      | chat, image analysis, audio analysis |
 * | `TRYON_MODEL`            | yes      | try-on images                        |
 * | `VIDEO_MODEL`            | yes      | try-on video                         |
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

/** The service account every Vertex call authenticates as. */
export interface VertexServiceAccount {
  clientEmail: string;
  privateKey: string;
  privateKeyId?: string;
}

/**
 * The one credential. A service account rather than an express-mode API key,
 * which serves a narrower model catalog and reports what it cannot see as a 404
 * naming the model — indistinguishable from a typo.
 *
 * `\n` is un-escaped because a key pasted out of the JSON key file carries it
 * literally; consumers strip whitespace but not that, and the base64 body then
 * fails to decode.
 */
export const vertexServiceAccount = (): VertexServiceAccount => ({
  clientEmail: requireEnv("GOOGLE_CLIENT_EMAIL"),
  privateKey: requireEnv("GOOGLE_PRIVATE_KEY").replace(/\\n/g, "\n"),
  privateKeyId: Deno.env.get("GOOGLE_PRIVATE_KEY_ID"),
});

/** GCP project id. Named explicitly now that no credential implies it. */
export const vertexProject = (): string => requireEnv("GOOGLE_CLOUD_PROJECT");

export const VERTEX_LOCATION = "global";

/** Model behind the chat agent and both analysis helpers. */
export const chatModel = (): string => requireEnv("CHAT_MODEL");

/** Model behind try-on image generation. */
export const tryonImageModel = (): string => requireEnv("TRYON_MODEL"); // gemini-3.1-flash-image

/** Model behind try-on video generation. No sensible default to fall back on. */
export const tryonVideoModel = (): string => requireEnv("VIDEO_MODEL"); // veo-3.1-generate-001
