/**
 * Input rejection, shared by every feature core.
 *
 * `ValidationError` lives here rather than in try-on or chat for the reason
 * {@link QuotaExceededError} does: "the caller sent something we cannot run" is
 * not a property of what it was trying to run, and two structurally identical
 * classes could only ever differ by accident. One class also means a helper
 * shared between cores raises an error each core's classifier still recognises.
 *
 * The primitives below split by whether a missing value is legal, and the names
 * say which: `require*` decodes a mandatory field and throws when it cannot,
 * `normalize*` decodes an optional one and never throws. The `label` parameter
 * follows the same line — it exists only to name the field in an error, so its
 * presence marks exactly the functions that can raise one.
 */
import { nonEmptyStr } from "./text.ts";

export class ValidationError extends Error {}

/** Require a non-empty string, for guards and adapter request parsers. */
export function requireString(value: unknown, label: string): string {
  if (typeof value !== "string" || value.length === 0) {
    throw new ValidationError(`${label} is required`);
  }
  return value;
}

/**
 * Trim an optional text field; blank or non-string becomes undefined. The
 * shared `nonEmptyStr` spelled for the optional-params convention, since a
 * core's optional fields are `undefined`-typed, not nullable.
 */
export function normalizeText(value: unknown): string | undefined {
  return nonEmptyStr(value) ?? undefined;
}

/** Parse raw body as JSON object, with conventional errors. */
export function parseJsonObject(rawBody: string): Record<string, unknown> {
  let body: unknown;
  try {
    body = JSON.parse(rawBody);
  } catch {
    throw new ValidationError("body must be valid JSON");
  }
  if (typeof body !== "object" || body === null) {
    throw new ValidationError("body must be an object");
  }
  return body as Record<string, unknown>;
}
