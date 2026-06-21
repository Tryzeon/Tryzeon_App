import { uploadTryonVideoToR2 } from "../_shared/r2.ts";
import { detectMimeType, base64ToUint8Array } from "../_shared/image-utils.ts";

const DEFAULT_VIDEO_PROMPT =
  "The person is wearing the new outfit and turning slightly to show the fit of the clothing. Natural movement, professional fashion video style.";

function buildVideoPrompt(transitionPrompt?: string): string {
  if (!transitionPrompt) {
    return DEFAULT_VIDEO_PROMPT;
  }

  let prompt = "The person is wearing the new outfit and showing the fit of the clothing.";
  prompt += ` Camera and transition style: ${transitionPrompt}.`;
  prompt += " Natural movement, professional fashion video style.";

  return prompt;
}

const MAX_POLL_ATTEMPTS = 60;
const POLL_INTERVAL_MS = 5000;

async function startVideoGeneration(
  tryonImageBase64: string,
  transitionPrompt?: string,
): Promise<string> {
  const prompt = buildVideoPrompt(transitionPrompt);
  
  const project = Deno.env.get("GOOGLE_CLOUD_PROJECT");
  const location = Deno.env.get("GOOGLE_CLOUD_LOCATION") || "us-central1";
  const model = Deno.env.get("VIDEO_MODEL");
  const apiKey = Deno.env.get("VERTEX_API_KEY");

  if (!project || !apiKey || !model) {
    throw new Error("GOOGLE_CLOUD_PROJECT, VIDEO_MODEL, and VERTEX_API_KEY environment variables are required");
  }

  const cleanBase64 = tryonImageBase64.replace(/^data:image\/[a-z]+;base64,/, '');
  const mimeType = detectMimeType(cleanBase64);

  const endpoint = `https://${location}-aiplatform.googleapis.com/v1/projects/${project}/locations/${location}/publishers/google/models/${model}:predictLongRunning`;

  const requestBody = {
    instances: [{
      prompt: prompt,
      image: {
        bytesBase64Encoded: cleanBase64,
        mimeType: mimeType,
      },
    }],
    parameters: {
      aspectRatio: "9:16",
      sampleCount: 1,
    },
  };

  const response = await fetch(endpoint, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-goog-api-key": apiKey,
    },
    body: JSON.stringify(requestBody),
  });

  if (!response.ok) {
    const errorText = await response.text();
    console.error("Failed to start video generation. Status:", response.status);
    console.error("Error response:", errorText);
    throw new Error(`Failed to start video generation: ${response.statusText} - ${errorText}`);
  }

  const data = await response.json();
  
  if (!data.name) {
    throw new Error("Invalid response from Vertex AI - no operation name");
  }

  return data.name;
}

async function pollForCompletion(operationName: string, userId: string): Promise<string> {
  const project = Deno.env.get("GOOGLE_CLOUD_PROJECT");
  const location = Deno.env.get("GOOGLE_CLOUD_LOCATION") || "us-central1";
  const model = Deno.env.get("VIDEO_MODEL");
  const apiKey = Deno.env.get("VERTEX_API_KEY");

  if (!project || !apiKey || !model) {
    throw new Error("GOOGLE_CLOUD_PROJECT, VIDEO_MODEL, and VERTEX_API_KEY environment variables are required");
  }

  const endpoint = `https://${location}-aiplatform.googleapis.com/v1/projects/${project}/locations/${location}/publishers/google/models/${model}:fetchPredictOperation`;

  let attempts = 0;

  while (attempts < MAX_POLL_ATTEMPTS) {
    await new Promise((resolve) => setTimeout(resolve, POLL_INTERVAL_MS));
    attempts++;

    const requestBody = {
      operationName: operationName,
    };

    const pollResponse = await fetch(endpoint, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-goog-api-key": apiKey,
      },
      body: JSON.stringify(requestBody),
    });

    if (!pollResponse.ok) {
      continue;
    }

    const pollData = await pollResponse.json();

    if (!pollData.done) continue;

    if (pollData.error) {
      throw new Error(`Video generation failed: ${pollData.error.message || JSON.stringify(pollData.error)}`);
    }

    const response = pollData.response;
    const videos = response?.videos;

    if (!videos || videos.length === 0) {
      throw new Error("Video generation failed - no video data returned");
    }

    const video = videos[0];

    if (video.gcsUri) {
      throw new Error("GCS storage not supported - please configure storageUri parameter or use inline response");
    }

    const videoBase64 = video.bytesBase64Encoded;

    if (!videoBase64) {
      throw new Error("Video generation failed - no video bytes returned");
    }

    const bytes = base64ToUint8Array(videoBase64);
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const fileName = `${userId}/${timestamp}.mp4`;

    const videoUrl = await uploadTryonVideoToR2(bytes, fileName);
    return videoUrl;
  }

  throw new Error(`Video generation timeout - polling limit reached (${MAX_POLL_ATTEMPTS * POLL_INTERVAL_MS / 1000} seconds)`);
}

export async function generateTryonVideo(
  tryonImageBase64: string,
  userId: string,
  transitionPrompt?: string,
): Promise<string> {
  const operationName = await startVideoGeneration(tryonImageBase64, transitionPrompt);
  return pollForCompletion(operationName, userId);
}
