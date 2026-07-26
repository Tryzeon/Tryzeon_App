/**
 * This function's NDJSON protocol: one JSON object per line.
 *
 * The frames are the app's, not the core's — a LINE adapter renders the same
 * outcomes as messages and never encodes a line of this. What both share is
 * `classifyCoreError`: the taxonomy is decided once, and each transport says
 * what it means in its own vocabulary.
 */
import { classifyCoreError } from "../_shared/chat/index.ts";

const ENCODER = new TextEncoder();

export function encodeEvent(ev: Record<string, unknown>): Uint8Array {
  return ENCODER.encode(JSON.stringify(ev) + "\n");
}

/**
 * The error frame for a failure raised after the 200 was committed, so the
 * client learns the outcome in-stream rather than from a status code.
 */
export function errorEvent(err: unknown): Record<string, unknown> {
  const info = classifyCoreError(err);
  if (info === null) {
    console.error("Chat stream error:", err);
    return { type: "error", code: "INTERNAL_ERROR" };
  }
  switch (info.kind) {
    case "quota":
      return { type: "error", code: "RATE_LIMIT_EXCEEDED", usage: info.usage };
    case "validation":
      return {
        type: "error",
        code: "VALIDATION_ERROR",
        message: info.message,
      };
  }
}
