/**
 * The failure kinds every feature core shares, and the single point that
 * classifies them.
 *
 * `ValidationError` and `QuotaExceededError` already live in `_shared` because
 * the conditions they describe belong to the input guard and the usage counter,
 * not to whatever was being run. The classifier over them belongs here for the
 * same reason: two cores narrowing the same two classes could only ever differ
 * by accident, and a kind added here reaches every adapter at once instead of
 * being copied into each feature's `instanceof` chain.
 *
 * A feature with failures of its own layers them on: it classifies its arms
 * first and falls back to {@link classifyCoreError}, so its info type is this
 * union plus its own. A feature with none — chat — uses this directly rather
 * than owning a taxonomy that would list nothing it raises.
 *
 * There is deliberately no "the model failed" kind. Whether an unusable model
 * result is an error at all is the feature's call: try-on raises one, chat
 * degrades to fallback text. That makes it a feature arm, never a shared one.
 */
import { type DailyUsage, QuotaExceededError } from "./quota.ts";
import { ValidationError } from "./validation.ts";

/**
 * A shared error narrowed to its kind, carrying exactly the payload a caller
 * needs to render it. Adding a case here forces every consumer's exhaustive
 * switch — including each feature's — to handle it.
 */
export type CoreErrorInfo =
  | { kind: "validation"; message: string }
  | { kind: "quota"; usage: DailyUsage | null };

/** Classifies a shared error, or returns null when it is neither. */
export function classifyCoreError(err: unknown): CoreErrorInfo | null {
  if (err instanceof ValidationError) {
    return { kind: "validation", message: err.message };
  }
  if (err instanceof QuotaExceededError) {
    return { kind: "quota", usage: err.usage };
  }
  return null;
}
