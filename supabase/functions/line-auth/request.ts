// `idToken` is the only field decoded, and that is a security property rather
// than a minimalism one: the session is minted for whichever email the auth
// user already carries, looked up from the user id. GoTrue's `generateLink`
// creates an account for an unknown email instead of failing, so a body that
// could name an email would make this endpoint an account factory. Extra
// fields are dropped, never honoured.
import { normalizeText, parseJsonObject, requireString } from "../_shared/validation.ts";

export interface LineAuthBody {
  idToken: string;
  nonce?: string;
}

export function parseLineAuthBody(rawBody: string): LineAuthBody {
  const b = parseJsonObject(rawBody);
  return {
    idToken: requireString(b.idToken, "idToken"),
    nonce: normalizeText(b.nonce),
  };
}
