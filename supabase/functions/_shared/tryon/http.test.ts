import { assertEquals } from "jsr:@std/assert";
import { tryonErrorResponse } from "./http.ts";
import { MissingAvatarError } from "./errors.ts";

Deno.test("tryonErrorResponse renders a missing avatar as 400 NO_AVATAR", async () => {
  // The exact body liff-tryon returned before the rule moved into the core.
  const res = tryonErrorResponse(new MissingAvatarError("no avatar on profile"))!;
  assertEquals(res.status, 400);
  assertEquals(await res.json(), {
    error: "No model photo on file",
    code: "NO_AVATAR",
  });
});
