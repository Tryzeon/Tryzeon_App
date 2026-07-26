/**
 * Try-on's error taxonomy: the shared kinds, plus the one try-on adds.
 *
 * The core is transport-agnostic: it raises these classes and never decides
 * what a caller should show. `classifyTryonError` is the one place that maps an
 * unknown error to a typed, payload-carrying descriptor, so every adapter
 * (HTTP responses, LINE push messages, anything later) renders from the same
 * classification instead of growing its own `instanceof` chain.
 *
 * Only `generation` is try-on's. A rejected input and a spent quota are raised
 * identically by every feature, so both the classes and the arms narrowing them
 * belong to `_shared/validation.ts`, `_shared/quota.ts` and
 * `_shared/errors.ts`; this module layers its own arm over them and delegates
 * the rest, and re-exports `ValidationError` so it still reads as the one list
 * of what a try-on job can raise.
 */

import { classifyCoreError, type CoreErrorInfo } from "../errors.ts";

export { ValidationError } from "../validation.ts";

export class GenerationFailedError extends Error {}

/**
 * A core error narrowed to its kind, carrying exactly the payload a caller
 * needs to render it. Adding a case here — or to {@link CoreErrorInfo} —
 * forces every consumer's exhaustive switch to handle it.
 */
export type TryonErrorInfo = CoreErrorInfo | { kind: "generation" };

/** Classifies a core error, or returns null when it did not come from the core. */
export function classifyTryonError(err: unknown): TryonErrorInfo | null {
  if (err instanceof GenerationFailedError) {
    return { kind: "generation" };
  }
  return classifyCoreError(err);
}
