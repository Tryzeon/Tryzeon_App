/**
 * Vertex AI implementations of the core's `ImageGenerator` / `VideoGenerator`
 * ports. This module owns everything provider-specific — endpoints, env vars,
 * request shapes, retry and polling. It builds no prompts (see `prompt.ts`) and
 * persists nothing: the video generator returns raw bytes and `run.ts` decides
 * where results are stored, so both modes share one persistence path.
 */
import { base64ToUint8Array, detectMimeType } from "../image-utils.ts";
import {
  tryonImageModel,
  tryonVideoModel,
  VERTEX_LOCATION,
  vertexApiKey,
  vertexProject,
} from "../vertex/config.ts";
import { buildTaskPrompt, buildVideoPrompt, SYSTEM_INSTRUCTION } from "./prompt.ts";

/**
 * Credentials, read on first use and kept for the isolate.
 *
 * Deliberately not read at import: `run.ts` names these generators as its
 * defaults, so anything that touches the try-on core pulls this module in —
 * including callers that only ever pass their own generator, and tests that
 * never reach the network. Reading at import would make Vertex configuration a
 * requirement for all of them.
 */
let credentials: { project: string; apiKey: string } | null = null;
const vertexCredentials = () =>
  credentials ??= { project: vertexProject(), apiKey: vertexApiKey() };

function modelEndpoint(model: string, method: string): string {
  const { project } = vertexCredentials();
  return `https://${VERTEX_LOCATION}-aiplatform.googleapis.com/v1/projects/` +
    `${project}/locations/${VERTEX_LOCATION}/publishers/google/models/` +
    `${model}:${method}`;
}

function postJson(endpoint: string, body: unknown): Promise<Response> {
  return fetch(endpoint, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-goog-api-key": vertexCredentials().apiKey,
    },
    body: JSON.stringify(body),
  });
}

/** Strips a `data:image/...;base64,` prefix if the caller left one on. */
function stripDataUri(base64: string): string {
  return base64.replace(/^data:image\/[a-z]+;base64,/, "");
}

interface InlineDataPart {
  inlineData: { mimeType: string; data: string };
}
type ContentPart = { text: string } | InlineDataPart;

function imagePart(base64: string): InlineDataPart {
  const clean = stripDataUri(base64);
  return { inlineData: { mimeType: detectMimeType(clean), data: clean } };
}

const MAX_IMAGE_ATTEMPTS = 3;

/**
 * Generates a try-on image via Vertex AI Gemini image generation.
 * Resolves to base64 image data, or null when the model returned no image.
 */
export async function generateTryonImage(
  avatarImage: string,
  garmentGroups: string[][],
  scenePrompt?: string,
  garmentDetails?: (string | undefined)[],
): Promise<string | null> {
  const taskPrompt = buildTaskPrompt(garmentGroups, scenePrompt, garmentDetails);

  const parts: ContentPart[] = [
    { text: taskPrompt },
    imagePart(avatarImage),
    ...garmentGroups.flat().map(imagePart),
  ];

  const requestBody = {
    contents: [{ role: "user", parts }],
    systemInstruction: {
      role: "system",
      parts: [{ text: SYSTEM_INSTRUCTION }],
    },
    generationConfig: {
      responseModalities: ["IMAGE"],
      temperature: 1.0,
      topP: 0.95,
      imageConfig: { aspectRatio: "9:16" },
    },
  };

  const endpoint = modelEndpoint(tryonImageModel(), "generateContent");

  for (let attempt = 1; attempt <= MAX_IMAGE_ATTEMPTS; attempt++) {
    const response = await postJson(endpoint, requestBody);

    if (!response.ok) {
      const errorText = await response.text();
      console.error(
        `Vertex image generation failed (${response.status}):`,
        errorText,
      );

      if (response.status === 429 && attempt < MAX_IMAGE_ATTEMPTS) {
        const backoffMs = 1000 * attempt;
        console.warn(
          `Vertex 429, retrying in ${backoffMs}ms ` +
            `(attempt ${attempt}/${MAX_IMAGE_ATTEMPTS})`,
        );
        await new Promise((resolve) => setTimeout(resolve, backoffMs));
        continue;
      }

      throw new Error(
        `Failed to generate image: ${response.statusText} - ${errorText}`,
      );
    }

    const data = await response.json();
    for (const candidate of data.candidates ?? []) {
      for (const part of candidate.content?.parts ?? []) {
        if (
          part.inlineData?.mimeType?.startsWith("image/") && part.inlineData.data
        ) {
          return part.inlineData.data as string;
        }
      }
    }

    // A 200 with no image part is a refusal, not a transient fault — retrying
    // the identical request would only burn quota.
    console.error("No image data in Vertex response:", JSON.stringify(data));
    return null;
  }

  // Every path above returns or throws; reaching here means the retry loop was
  // edited into a state that falls through. Fail loudly rather than returning
  // null, which the core would report to the user as a model refusal (422).
  throw new Error(
    "unreachable: Vertex image retry loop exited without a result",
  );
}

const MAX_POLL_ATTEMPTS = 60;
const POLL_INTERVAL_MS = 5000;

async function startVideoGeneration(
  tryonImageBase64: string,
  transitionPrompt?: string,
): Promise<string> {
  const clean = stripDataUri(tryonImageBase64);

  const response = await postJson(
    modelEndpoint(tryonVideoModel(), "predictLongRunning"),
    {
      instances: [{
        prompt: buildVideoPrompt(transitionPrompt),
        image: {
          bytesBase64Encoded: clean,
          mimeType: detectMimeType(clean),
        },
      }],
      parameters: { aspectRatio: "9:16", sampleCount: 1 },
    },
  );

  if (!response.ok) {
    const errorText = await response.text();
    console.error(
      `Vertex video start failed (${response.status}):`,
      errorText,
    );
    throw new Error(
      `Failed to start video generation: ${response.statusText} - ${errorText}`,
    );
  }

  const data = await response.json();
  if (!data.name) {
    throw new Error("Invalid response from Vertex AI - no operation name");
  }
  return data.name as string;
}

async function pollForVideoBytes(operationName: string): Promise<Uint8Array> {
  const endpoint = modelEndpoint(tryonVideoModel(), "fetchPredictOperation");

  for (let attempt = 0; attempt < MAX_POLL_ATTEMPTS; attempt++) {
    await new Promise((resolve) => setTimeout(resolve, POLL_INTERVAL_MS));

    const pollResponse = await postJson(endpoint, {
      operationName,
    });
    if (!pollResponse.ok) continue;

    const pollData = await pollResponse.json();
    if (!pollData.done) continue;

    if (pollData.error) {
      throw new Error(
        `Video generation failed: ${
          pollData.error.message || JSON.stringify(pollData.error)
        }`,
      );
    }

    const videos = pollData.response?.videos;
    if (!videos || videos.length === 0) {
      throw new Error("Video generation failed - no video data returned");
    }

    const video = videos[0];
    if (video.gcsUri) {
      throw new Error(
        "GCS storage not supported - please configure storageUri parameter or use inline response",
      );
    }
    if (!video.bytesBase64Encoded) {
      throw new Error("Video generation failed - no video bytes returned");
    }

    return base64ToUint8Array(video.bytesBase64Encoded);
  }

  throw new Error(
    `Video generation timeout - polling limit reached (${
      MAX_POLL_ATTEMPTS * POLL_INTERVAL_MS / 1000
    } seconds)`,
  );
}

/**
 * Animates a generated try-on image via Vertex AI and returns the raw video
 * bytes. Persistence is the core's job, not this module's.
 */
export async function generateTryonVideo(
  tryonImageBase64: string,
  transitionPrompt?: string,
): Promise<Uint8Array> {
  const operationName = await startVideoGeneration(
    tryonImageBase64,
    transitionPrompt,
  );
  return pollForVideoBytes(operationName);
}
