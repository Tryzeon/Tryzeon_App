/**
 * Owns what is provider-specific; builds no prompts (see `prompt.ts`) and
 * persists nothing.
 */
import { experimental_generateVideo, generateText } from "ai";
import { base64ToUint8Array } from "../image-utils.ts";
import {
  tryonAdvancedImageModel,
  tryonImageModel,
  tryonVideoModel,
} from "../vertex/config.ts";
import { rethrowAsBusy } from "../vertex/errors.ts";
import { vertexModel, vertexVideoModel } from "../vertex/provider.ts";
import {
  buildTaskPrompt,
  buildVideoPrompt,
  SYSTEM_INSTRUCTION,
} from "./prompt.ts";
import type { ImageGenerationOptions } from "./types.ts";

/**
 * An `image` part rather than a `file` one so the SDK settles the media type: a
 * `file` part is taken at its word, and declaring the type wrong is a
 * documented way to make Gemini return no image at all.
 */
function imagePart(base64: string) {
  return { type: "image" as const, image: base64 };
}

/**
 * `responseModalities` and `imageConfig` are Gemini's own settings, so they
 * travel under `providerOptions.vertex` rather than as call options.
 */
export async function generateTryonImage(
  avatarImage: string,
  garmentGroups: string[][],
  opts: ImageGenerationOptions = {},
): Promise<string | null> {
  const taskPrompt = buildTaskPrompt(garmentGroups, opts);
  console.log("[tryon] task prompt:\n" + taskPrompt);

  // Read at call time, not at module load: a deployment missing the advanced
  // model must still serve standard jobs.
  const modelName = opts.engine === "advanced"
    ? tryonAdvancedImageModel()
    : tryonImageModel();

  const { files, finishReason } = await generateText({
    model: vertexModel(modelName),
    system: SYSTEM_INSTRUCTION,
    messages: [{
      role: "user",
      content: [
        {
          type: "text",
          text: taskPrompt,
        },
        imagePart(avatarImage),
        ...garmentGroups.flat().map(imagePart),
      ],
    }],
    providerOptions: {
      vertex: {
        responseModalities: ["IMAGE"],
        imageConfig: { aspectRatio: "9:16" },
      },
    },
  }).catch(rethrowAsBusy);

  const image = files.find((file) => file.mediaType.startsWith("image/"));
  if (!image) {
    console.error("No image in Vertex response, finishReason:", finishReason);
    return null;
  }
  return image.base64;
}

/**
 * Half the SDK's default. The platform ends the request at 150s, so the poll
 * interval is the tail of that budget: at 10s a video that finished at 145s is
 * missed, at 5s it still makes it back.
 */
const POLL_INTERVAL_MS = 5000;

/**
 * Veo is long-running and this waits it out inside the request: a job outlives
 * a dropped connection but its result does not, so a caller that goes away
 * cannot pick it up again.
 */
export async function generateTryonVideo(
  tryonImageBase64: string,
  transitionPrompt?: string,
): Promise<Uint8Array> {
  const { video } = await experimental_generateVideo({
    model: vertexVideoModel(tryonVideoModel()),
    prompt: {
      image: tryonImageBase64,
      text: buildVideoPrompt(transitionPrompt),
    },
    aspectRatio: "9:16",
    generateAudio: false,
    providerOptions: { vertex: { pollIntervalMs: POLL_INTERVAL_MS } },
  }).catch(rethrowAsBusy);

  return base64ToUint8Array(video.base64);
}
