/**
 * Public surface of the try-on core. It is transport-agnostic: nothing
 * reachable from here knows about HTTP, CORS, LINE, or any wire format —
 * `http.ts` sits in this folder but is deliberately not re-exported.
 */

// Running a job.
export { runTryonJob, type RunTryonJobDeps } from "./run.ts";
export { supabaseQuota } from "./quota.ts";
export type {
  AvatarResolver,
  BodyResolver,
  ImageGenerationOptions,
  ImageGenerator,
  ImageUploader,
  ProductResolver,
  WardrobeResolver,
  QuotaFactory,
  UsageCounter,
  VideoGenerator,
  VideoUploader,
} from "./types.ts";

// Describing a job and reading its result.
export { LIMITS } from "./types.ts";
export type {
  AvatarOverride,
  BaseImage,
  GarmentInput,
  GarmentMaterial,
  ProductRef,
  WardrobeRef,
  ImageSource,
  ResolvedGarment,
  TryonEngine,
  TryonMode,
  TryonParams,
  TryonResult,
} from "./types.ts";

// Classifying a failure. `ValidationError` is a constructor too: adapter
// request parsers raise it so a malformed body and a rejected param reach the
// caller as one kind of error.
export {
  classifyTryonError,
  type TryonErrorInfo,
  ValidationError,
} from "./errors.ts";

// Decoding wire fields, shared with every adapter's request parser.
export {
  normalizeText,
  parseJsonObject,
  requireString,
} from "../validation.ts";
