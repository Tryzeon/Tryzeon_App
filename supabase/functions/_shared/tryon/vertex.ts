/**
 * Vertex AI implementations of the core's `ImageGenerator` / `VideoGenerator`
 * ports, over the same AI SDK provider every other Vertex caller uses. This
 * module owns what is provider-specific — model names and the Gemini/Veo
 * settings that reach Vertex through `providerOptions`. It builds no prompts
 * (see `prompt.ts`) and persists nothing: the video generator returns raw bytes
 * and `run.ts` decides where results are stored, so both modes share one
 * persistence path.
 */
import { experimental_generateVideo, generateText } from "npm:ai@^6.0.208";
import { base64ToUint8Array } from "../image-utils.ts";
import { tryonImageModel, tryonVideoModel } from "../vertex/config.ts";
import { rethrowAsBusy } from "../vertex/errors.ts";
import { vertexModel, vertexVideoModel } from "../vertex/provider.ts";
import {
  buildTaskPrompt,
  buildVideoPrompt,
  SYSTEM_INSTRUCTION,
} from "./prompt.ts";

/**
 * An `image` part rather than a `file` one so the SDK settles the media type: it
 * reads a `data:` prefix when the caller left one on — the avatar override is
 * guarded as a non-empty string, not as bare base64 — and otherwise sniffs the
 * bytes. A `file` part is taken at its word, which would put us back to
 * declaring the type ourselves, and declaring it wrong is a documented way to
 * make Gemini return no image at all.
 */
function imagePart(base64: string) {
  return { type: "image" as const, image: base64 };
}

/**
 * Generates a try-on image via Vertex AI Gemini image generation.
 * Resolves to base64 image data, or null when the model returned no image.
 *
 * `responseModalities` and `imageConfig` are Gemini's own settings, so they
 * travel under `providerOptions.vertex` rather than as call options; the
 * provider validates them against its schema before they reach the API.
 */
export async function generateTryonImage(
  avatarImage: string,
  garmentGroups: string[][],
  opts: {
    scenePrompt?: string;
    garmentDetails?: (string | undefined)[];
    garmentFits?: (string | undefined)[];
  } = {},
): Promise<string | null> {
  const { files, finishReason } = await generateText({
    model: vertexModel(tryonImageModel()),
    system: SYSTEM_INSTRUCTION,
    messages: [{
      role: "user",
      content: [
        {
          type: "text",
          text: buildTaskPrompt(garmentGroups, opts),
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
 * missed, at 5s it still makes it back. The SDK's own poll timeout is left at
 * its default — no value we could set is reachable before the platform's.
 */
const POLL_INTERVAL_MS = 5000;

/**
 * Animates a generated try-on image via Vertex AI and returns the raw video
 * bytes. Persistence is the core's job, not this module's.
 *
 * Veo is long-running, and this waits it out inside the request: a job outlives
 * a dropped connection but its result does not, so a caller that goes away
 * cannot pick it up again. Fixing that means handing the operation name back and
 * polling from a second entry point, which is a change to the core's contract,
 * not to this adapter.
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
