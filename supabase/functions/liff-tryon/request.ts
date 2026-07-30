// The LIFF web app's wire format. Decoding uses the core's `requireString` and
// `ValidationError`, so a body-parse failure and a core resolution failure are
// the same class, both reach `tryonErrorResponse`, and both map to one 400.
//
// The body carries no photo: the avatar is the one stored on the user's
// profile, resolved server-side, exactly as the LINE chat try-on does.
import { parseJsonObject, requireString } from "../_shared/tryon/index.ts";

export interface LiffTryonBody {
  idToken: string;
  productId: string;
}

/**
 * Decode the raw request body. Owns `JSON.parse` for the same reason the app's
 * parser does: malformed JSON is a malformed request, not an unclassified
 * fault, so it raises a ValidationError and lands on 400 like every other bad
 * body — previously it escaped as a SyntaxError and became a 500.
 */
export function parseLiffTryonBody(rawBody: string): LiffTryonBody {
  const b = parseJsonObject(rawBody);
  return {
    idToken: requireString(b.idToken, "idToken"),
    productId: requireString(b.productId, "productId"),
  };
}

