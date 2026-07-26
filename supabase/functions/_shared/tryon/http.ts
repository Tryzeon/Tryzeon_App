/**
 * HTTP rendering of try-on core errors.
 *
 * This module sits beside the core but is not part of it, and the boundary is
 * directional rather than positional: it imports the core, the core imports
 * nothing from here, and `index.ts` does not re-export it. An adapter reaching
 * for this reaches past the core's public surface deliberately — that deep
 * import is the signal it is taking on a transport concern.
 *
 * Every HTTP entry point (app, LIFF) shares it, so one error class can never
 * grow two different status codes or bodies. Non-HTTP adapters (line-webhook)
 * render the same `classifyTryonError` result their own way instead of
 * re-deriving the taxonomy. Callers keep their own handling for non-core errors
 * and for transport concerns such as CORS.
 */
import { jsonError, jsonRateLimited } from "../http.ts";
import { classifyTryonError } from "./index.ts";

/** Maps a core error to its canonical response, or null if it isn't a core error. */
export function tryonErrorResponse(err: unknown): Response | null {
  const info = classifyTryonError(err);
  if (info === null) return null;

  switch (info.kind) {
    case "validation":
      return jsonError(info.message, "VALIDATION_ERROR", 400);
    case "quota":
      return jsonRateLimited(info.usage);
    case "generation":
      return jsonError("Image generation failed", "AI_GENERATION_FAILED", 422);
  }
}
