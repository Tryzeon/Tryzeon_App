/**
 * The app's wire format for the `tryon` function.
 *
 * Request parsing is an adapter concern: this JSON body is what the Flutter
 * client speaks, and no other try-on caller speaks it (LIFF has its own body in
 * `liff-tryon/request.ts`; line-webhook has no body at all). It lives here for
 * the same reason theirs lives there.
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
  ImageSource,
  TryonParams,
} from "../_shared/tryon/index.ts";

/** Decode one raw garment into the typed shape. */
function decodeGarment(raw: unknown): GarmentInput {
  if (typeof raw !== "object" || raw === null) {
    throw new ValidationError("each garment must be an object");
  }
  const r = raw as Record<string, unknown>;
  return "productId" in r
    ? { productId: r.productId as string }
    : { images: r.images as ImageSource[] };
}

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

  if (!Array.isArray(b.garments)) {
    throw new ValidationError("garments must be an array");
  }

  return {
    userId,
    avatar: b.avatar as ImageSource,
    garments: b.garments.map(decodeGarment),
    // Omitting `mode` means the default; naming an unknown one is an error, and
    // the core raises it. Mapping every unrecognised value onto "image" would
    // charge the image quota for a request that asked for something else, and
    // would leave the core's own mode check unreachable from this adapter.
    mode: (b.mode ?? "image") as TryonParams["mode"],
    scenePrompt: normalizeText(b.scenePrompt),
    transitionPrompt: normalizeText(b.transitionPrompt),
  };
}
