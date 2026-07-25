// Text coercions shared across functions.

/** Trimmed string, or null when the value is missing, not a string, or blank. */
export function nonEmptyStr(value: unknown): string | null {
  const trimmed = typeof value === "string" ? value.trim() : "";
  return trimmed.length > 0 ? trimmed : null;
}
