import { assertEquals } from "jsr:@std/assert";
import { classifyCoreError } from "./errors.ts";
import { ValidationError } from "./validation.ts";
import { type DailyUsage, QuotaExceededError } from "./quota.ts";

const USAGE: DailyUsage = {
  user_id: "u1",
  usage_date: "2026-07-26",
  tryon_count: 0,
  chat_count: 5,
  video_count: 0,
};

Deno.test("classifyCoreError carries the message for validation errors", () => {
  assertEquals(classifyCoreError(new ValidationError("messages must be an array")), {
    kind: "validation",
    message: "messages must be an array",
  });
});

Deno.test("classifyCoreError carries usage for quota errors", () => {
  assertEquals(classifyCoreError(new QuotaExceededError(USAGE)), {
    kind: "quota",
    usage: USAGE,
  });
});

Deno.test("classifyCoreError returns null for anything else", () => {
  assertEquals(classifyCoreError(new Error("vertex 503")), null);
  assertEquals(classifyCoreError(new TypeError("boom")), null);
  assertEquals(classifyCoreError("not an error"), null);
  assertEquals(classifyCoreError(null), null);
});
