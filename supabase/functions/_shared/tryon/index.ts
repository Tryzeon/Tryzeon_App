/**
 * Public surface of the try-on core.
 *
 * The core spans "typed params -> persisted result URL": validation, quota,
 * product resolution, source loading, generation, persistence. It is
 * transport-agnostic — nothing reachable from here knows about HTTP, CORS,
 * LINE, or any wire format. Adapters own who the caller is, what body shape
 * they speak, and how the result is delivered.
 *
 * `http.ts` sits in this folder but outside that surface: it depends on the
 * core, the core does not depend on it, and it is deliberately not re-exported
 * below, so an adapter picks up transport concerns by importing it directly.
 *
 * What belongs here is what a caller needs in order to run a job, describe its
 * inputs and outputs, and classify its failures — nothing more. The pieces the
 * core wires up for itself (`validateTryonParams`, `resolveProductGarment`,
 * `supabaseQuota`, `buildProductGarmentDetail`, `isGarmentRef`) are reachable
 * by their own modules, and are left out so that "public surface" stays a
 * claim about this file rather than a description of the folder. Quota
 * exhaustion is likewise not ours to publish: `QuotaExceededError` belongs to
 * `_shared/quota.ts`, and adapters read it through `classifyTryonError`.
 */

// Running a job. The ports come along because `RunTryonJobDeps` is part of
// `runTryonJob`'s signature and its members would otherwise be unnameable.
export { runTryonJob, type RunTryonJobDeps } from "./run.ts";
export type {
  AvatarResolver,
  ImageGenerator,
  ImageUploader,
  ProductResolver,
  QuotaFactory,
  UsageCounter,
  VideoGenerator,
  VideoUploader,
} from "./types.ts";

// Describing a job and reading its result.
export { LIMITS } from "./types.ts";
export type {
  AvatarOverride,
  GarmentInput,
  GarmentMaterial,
  GarmentRef,
  ImageSource,
  ResolvedGarment,
  TryonClients,
  TryonMode,
  TryonParams,
  TryonResult,
} from "./types.ts";

// Classifying a failure. `ValidationError` is exported as a constructor too:
// adapter request parsers raise it so a malformed body and a rejected param
// reach the caller as one kind of error.
export {
  classifyTryonError,
  type TryonErrorInfo,
  ValidationError,
} from "./errors.ts";

// Decoding wire fields, shared with every adapter's request parser. The generic
// two are re-exported from `_shared/validation.ts` rather than owned here: an
// adapter parsing a try-on body should not have to know which of its primitives
// happen to be try-on's.
export { requireImageSource } from "./validate.ts";
export { normalizeText, parseJsonObject, requireString } from "../validation.ts";
