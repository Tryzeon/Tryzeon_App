/**
 * The wire format for the `tryon` function.
 *
 * Request parsing is an adapter concern, and this is the adapter: both HTTP
 * callers speak this body — the Flutter app and the LIFF web app, which used to
 * have its own in `liff-tryon/request.ts` and now sends `garments` like
 * everyone else. line-webhook has no body at all and builds its params
 * directly.
 *
 * Structural narrowing and trimming only — every domain invariant (non-empty
 * garments, count limits, length caps, usable image sources) is enforced by
 * `validateTryonParams` inside `runTryonJob`, the single guard all entry points
 * share. A malformed value survives decoding as a typed shape and is rejected
 * there, so this module never duplicates the rules.
 *
 * Hence the unchecked casts below: they assert the shape the wire format is
 * supposed to have, and the very next thing that happens to the result is the
 * core checking whether it really does. Validating here as well would run the
 * same guard twice and give the two layers a chance to disagree. The `object`
 * and `Array.isArray` tests that remain are not guards — decoding cannot
 * traverse the body without them.
 */
import {
  normalizeText,
  parseJsonObject,
  ValidationError,
} from "../_shared/tryon/index.ts";
import type {
  GarmentInput,
  TryonParams,
} from "../_shared/tryon/index.ts";

/**
 * Decode the raw request body into typed TryonParams, attaching the
 * caller-supplied (authenticated) userId.
 *
 * Takes the raw text rather than pre-parsed JSON: "the body is JSON" is part of
 * the wire format, and `parseJsonObject` is where every adapter agrees on what
 * that means, so malformed input raises the same ValidationError as a malformed
 * field and the entry point needs no special case to turn one into a 400.
 */
export function parseTryonParams(rawBody: string, userId: string): TryonParams {
  const b = parseJsonObject(rawBody);

  // Absent is legal: an animate request names a finished picture instead of
  // garments. Present-but-not-an-array is still undecodable, so it still stops
  // here.
  if (b.garments !== undefined && !Array.isArray(b.garments)) {
    throw new ValidationError("garments must be an array");
  }

  return {
    userId,
    avatar: b.avatar as TryonParams["avatar"],
    garments: (b.garments ?? []) as GarmentInput[],
    // Omitting `mode` means the default; naming an unknown one is an error, and
    // the core raises it. Mapping every unrecognised value onto "image" would
    // charge the image quota for a request that asked for something else, and
    // would leave the core's own mode check unreachable from this adapter.
    mode: (b.mode ?? "image") as TryonParams["mode"],
    scenePrompt: normalizeText(b.scenePrompt),
    stylingPrompt: normalizeText(b.stylingPrompt),
    transitionPrompt: normalizeText(b.transitionPrompt),
    baseImage: b.baseImage as TryonParams["baseImage"],
  };
}
