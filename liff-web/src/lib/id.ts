/** Purely local identifier — the server knows nothing about it, it only has to
 * be unique within this session. */
export function newId(): string {
  return typeof crypto.randomUUID === "function"
    ? crypto.randomUUID()
    : `${Date.now()}-${Math.random().toString(36).slice(2)}`;
}
