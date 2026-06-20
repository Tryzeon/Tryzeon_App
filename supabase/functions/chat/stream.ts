// One NDJSON line per event: JSON object + "\n", UTF-8 encoded for the stream.
const ENCODER = new TextEncoder();

export function encodeEvent(ev: Record<string, unknown>): Uint8Array {
  return ENCODER.encode(JSON.stringify(ev) + "\n");
}
