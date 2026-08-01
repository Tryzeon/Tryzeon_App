/**
 * HTTP rendering of try-on core errors.
 *
 * This module sits beside the core but is not part of it, and the boundary is
 * directional rather than positional: it imports the core, the core imports
 * nothing from here, and `index.ts` does not re-export it. An adapter reaching
 * for this reaches past the core's public surface deliberately — that deep
 * import is the signal it is taking on a transport concern.
 *
 * It renders only try-on's own kind; the shared ones go to `coreErrorResponse`
 * so a validation error cannot answer 400 here and something else elsewhere.
 * Every HTTP entry point (app, LIFF) shares this, and non-HTTP adapters
 * (line-webhook) render the same `classifyTryonError` result their own way
 * instead of re-deriving the taxonomy. Callers keep their own handling for
 * non-core errors and for transport concerns such as CORS.
 */
import { coreErrorResponse, jsonError } from "../http.ts";
import { classifyTryonError } from "./errors.ts";

/** Maps a core error to its canonical response, or null if it isn't a core error. */
export function tryonErrorResponse(err: unknown): Response | null {
  const info = classifyTryonError(err);
  if (info === null) return null;

  switch (info.kind) {
    case "generation":
      return jsonError("Image generation failed", "AI_GENERATION_FAILED", 422);
    case "missingAvatar":
      return jsonError("No model photo on file", "NO_AVATAR", 400);
    case "validation":
    case "quota":
      return coreErrorResponse(info);
  }
}
