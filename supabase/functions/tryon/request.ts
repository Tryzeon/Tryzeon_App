/**
 * Structural narrowing and trimming only — every domain invariant (non-empty
 * garments, count limits, length caps, usable image sources) is enforced by
 * `validateTryonParams` inside `runTryonJob`, the single guard all entry points
 * share. Hence the unchecked casts below: validating here as well would run the
 * same guard twice and give the two layers a chance to disagree.
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
 * Takes raw text rather than pre-parsed JSON so that a malformed body raises the
 * same ValidationError as a malformed field, and the entry point needs no
 * special case to turn one into a 400.
 */
export function parseTryonParams(rawBody: string, userId: string): TryonParams {
  const b = parseJsonObject(rawBody);

  // Absent is legal: an animate request names a finished picture instead.
  if (b.garments !== undefined && !Array.isArray(b.garments)) {
    throw new ValidationError("garments must be an array");
  }

  return {
    userId,
    avatar: b.avatar as TryonParams["avatar"],
    garments: (b.garments ?? []) as GarmentInput[],
    // An unknown mode is passed through for the core to reject: mapping it onto
    // "image" would charge the image quota for a job nobody asked for.
    mode: (b.mode ?? "image") as TryonParams["mode"],
    engine: b.engine as TryonParams["engine"],
    scenePrompt: normalizeText(b.scenePrompt),
    stylingPrompt: normalizeText(b.stylingPrompt),
    transitionPrompt: normalizeText(b.transitionPrompt),
    baseImage: b.baseImage as TryonParams["baseImage"],
  };
}
