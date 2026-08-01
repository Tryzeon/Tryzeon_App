import { assertEquals } from "jsr:@std/assert";
import {
  classifyTryonError,
  GenerationFailedError,
  MissingAvatarError,
  ValidationError,
} from "./errors.ts";
import { type DailyUsage, QuotaExceededError } from "../quota.ts";

const USAGE: DailyUsage = {
  user_id: "u1",
  usage_date: "2026-07-26",
  tryon_count: 5,
  chat_count: 0,
  video_count: 0,
};

Deno.test("classifyTryonError carries the message for validation errors", () => {
  assertEquals(classifyTryonError(new ValidationError("avatar is required")), {
    kind: "validation",
    message: "avatar is required",
  });
});

Deno.test("classifyTryonError carries usage for quota errors", () => {
  assertEquals(classifyTryonError(new QuotaExceededError(USAGE)), {
    kind: "quota",
    usage: USAGE,
  });
});

Deno.test("classifyTryonError narrows generation failures", () => {
  assertEquals(classifyTryonError(new GenerationFailedError("null")), {
    kind: "generation",
  });
});

Deno.test("classifyTryonError returns null for foreign errors", () => {
  assertEquals(classifyTryonError(new Error("storage down")), null);
  assertEquals(classifyTryonError(new TypeError("boom")), null);
  assertEquals(classifyTryonError("not an error"), null);
  assertEquals(classifyTryonError(undefined), null);
});

Deno.test("classifyTryonError narrows a missing avatar", () => {
  assertEquals(classifyTryonError(new MissingAvatarError("no avatar on profile")), {
    kind: "missingAvatar",
  });
});
