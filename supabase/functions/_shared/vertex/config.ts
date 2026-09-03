/**
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
 * | `TRYON_MODEL`            | yes          | try-on images, standard engine       |
 * | `TRYON_MODEL_ADVANCED`   | yes          | try-on images, advanced engine       |
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

export interface VertexServiceAccount {
  projectId: string;
  clientEmail: string;
  privateKey: string;
  privateKeyId?: string;
}

const REQUIRED_FIELDS = ["project_id", "client_email", "private_key"] as const;

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

export const vertexLocation = (): string => Deno.env.get("VERTEX_LOCATION") ?? "global";

export const chatModel = (): string => requireEnv("CHAT_MODEL");

export const tryonImageModel = (): string => requireEnv("TRYON_MODEL"); // gemini-2.5-flash-image
export const tryonAdvancedImageModel = (): string => requireEnv("TRYON_MODEL_ADVANCED"); // gemini-3.1-flash-image

export const tryonVideoModel = (): string => requireEnv("VIDEO_MODEL"); // veo-3.1-generate-001
