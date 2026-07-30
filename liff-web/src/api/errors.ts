/** A non-2xx response from an edge function, carrying its `{ error, code }` body. */
export class ApiError extends Error {
  constructor(
    message: string,
    readonly status: number,
    readonly code?: string,
  ) {
    super(message);
    this.name = "ApiError";
  }
}

/**
 * Reads a fetch Response as JSON, raising ApiError on a non-2xx so every caller
 * gets the server's `code` without re-deriving the envelope shape.
 */
export async function readJson(resp: Response): Promise<Record<string, unknown>> {
  const data = (await resp.json().catch(() => ({}))) as Record<string, unknown>;
  if (!resp.ok) {
    throw new ApiError(
      typeof data.error === "string" ? data.error : "request failed",
      resp.status,
      typeof data.code === "string" ? data.code : undefined,
    );
  }
  return data;
}
