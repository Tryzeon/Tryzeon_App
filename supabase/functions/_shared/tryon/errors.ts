/**
 * Try-on error taxonomy and its single classification point.
 *
 * The core is transport-agnostic: it raises these classes and never decides
 * what a caller should show. `classifyTryonError` is the one place that maps an
 * unknown error to a typed, payload-carrying descriptor, so every adapter
 * (HTTP responses, LINE push messages, anything later) renders from the same
 * classification instead of growing its own `instanceof` chain.
 *
 * Running out of quota is not a try-on failure mode — it is the shared
 * counter's, raised identically for chat — so that class is owned by
 * `_shared/quota.ts` and merely classified here.
 */

import { type DailyUsage, QuotaExceededError } from "../quota.ts";

export class ValidationError extends Error {}

export class GenerationFailedError extends Error {}

/**
 * A core error narrowed to its kind, carrying exactly the payload a caller
 * needs to render it. Adding a case here forces every consumer's exhaustive
 * switch to handle it.
 */
export type TryonErrorInfo =
  | { kind: "validation"; message: string }
  | { kind: "quota"; usage: DailyUsage | null }
  | { kind: "generation" };

/** Classifies a core error, or returns null when it did not come from the core. */
export function classifyTryonError(err: unknown): TryonErrorInfo | null {
  if (err instanceof ValidationError) {
    return { kind: "validation", message: err.message };
  }
  if (err instanceof QuotaExceededError) {
    return { kind: "quota", usage: err.usage };
  }
  if (err instanceof GenerationFailedError) {
    return { kind: "generation" };
  }
  return null;
}
