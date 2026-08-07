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
 * checking, and rotating a key meant finding every reader. The credential is now
 * the key file itself, so the project id and the signing key cannot disagree:
 * they are fields of one value that is replaced whole.
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
 * | Variable                 | Required     | Read by                              |
 * | ------------------------ | ------------ | ------------------------------------ |
 * | `GOOGLE_SERVICE_ACCOUNT` | yes          | everything — credential and project  |
 * | `CHAT_MODEL`             | yes          | chat, image analysis, audio analysis |
 * | `TRYON_MODEL`            | yes          | try-on images                        |
 * | `VIDEO_MODEL`            | yes          | try-on video                         |
 * | `VERTEX_LOCATION`        | no, `global` | everything — the endpoint region     |
 *
 * `GOOGLE_SERVICE_ACCOUNT` is the downloaded key file, pasted whole.
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

/** The service account every Vertex call authenticates as, and its project. */
export interface VertexServiceAccount {
  projectId: string;
  clientEmail: string;
  privateKey: string;
  privateKeyId?: string;
}

/** Field names as they appear in a Google key file, for the error message. */
const REQUIRED_FIELDS = ["project_id", "client_email", "private_key"] as const;

/**
 * Decodes the key file into the fields the provider needs. Exported for its
 * tests: it is the one place a deployment's credential can be malformed, and
 * every failure here reads as "Vertex is down" from the outside.
 */
export function parseServiceAccount(raw: string): VertexServiceAccount {
  let key: Record<string, unknown>;
  try {
    key = JSON.parse(raw);
  } catch {
    throw new Error("GOOGLE_SERVICE_ACCOUNT is not valid JSON");
  }

  const missing = REQUIRED_FIELDS.filter((field) => typeof key[field] !== "string");
  if (missing.length > 0) {
    throw new Error(`GOOGLE_SERVICE_ACCOUNT is missing: ${missing.join(", ")}`);
  }

  return {
    projectId: key.project_id as string,
    clientEmail: key.client_email as string,
    privateKey: key.private_key as string,
    privateKeyId: typeof key.private_key_id === "string" ? key.private_key_id : undefined,
  };
}

let serviceAccount: VertexServiceAccount | null = null;

/**
 * The one credential, parsed once for the isolate. A service account rather than
 * an express-mode API key, which serves a narrower model catalog and reports
 * what it cannot see as a 404 naming the model — indistinguishable from a typo.
 */
export function vertexServiceAccount(): VertexServiceAccount {
  return serviceAccount ??= parseServiceAccount(requireEnv("GOOGLE_SERVICE_ACCOUNT"));
}

/** Region every Vertex call is routed to. `global` serves the models we use. */
export const vertexLocation = (): string => Deno.env.get("VERTEX_LOCATION") ?? "global";

/** Model behind the chat agent and both analysis helpers. */
export const chatModel = (): string => requireEnv("CHAT_MODEL");

/** Model behind try-on image generation. */
export const tryonImageModel = (): string => requireEnv("TRYON_MODEL"); // gemini-3.1-flash-image

/** Model behind try-on video generation. No sensible default to fall back on. */
export const tryonVideoModel = (): string => requireEnv("VIDEO_MODEL"); // veo-3.1-generate-001
