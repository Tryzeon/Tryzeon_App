import { classifyCoreError, CORE_ERROR_CODE } from "../_shared/chat/index.ts";

const ENCODER = new TextEncoder();

export function encodeEvent(ev: Record<string, unknown>): Uint8Array {
  return ENCODER.encode(JSON.stringify(ev) + "\n");
}

/** For a failure raised after the 200 was committed: no status code is left to use. */
export function errorEvent(err: unknown): Record<string, unknown> {
  const info = classifyCoreError(err);
  if (info === null) {
    console.error("Chat stream error:", err);
    return { type: "error", code: "INTERNAL_ERROR" };
  }
  switch (info.kind) {
    case "quota":
      return { type: "error", code: CORE_ERROR_CODE.quota, usage: info.usage };
    case "busy":
      return { type: "error", code: CORE_ERROR_CODE.busy };
    case "validation":
      return {
        type: "error",
        code: CORE_ERROR_CODE.validation,
        message: info.message,
      };
  }
}
