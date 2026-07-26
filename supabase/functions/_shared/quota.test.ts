import { assertEquals } from "jsr:@std/assert";
import { supabaseUsageCounter } from "./quota.ts";
import { fakeQuotaAdmin, SAMPLE_USAGE } from "./quota.testing.ts";

Deno.test("supabaseUsageCounter charges the named feature and echoes the usage row", async () => {
  const admin = fakeQuotaAdmin();
  const result = await supabaseUsageCounter(admin.client, "u1", "chat").charge();
  assertEquals(result, { allowed: true, usage: SAMPLE_USAGE });
  assertEquals(admin.calls, [{
    fn: "increment_feature_usage",
    args: { p_user_id: "u1", p_feature_name: "chat" },
  }]);
});

Deno.test("supabaseUsageCounter reports a rejection without refunding", async () => {
  const admin = fakeQuotaAdmin(false);
  const counter = supabaseUsageCounter(admin.client, "u1", "tryon");
  assertEquals((await counter.charge()).allowed, false);
  await counter.refund();
  assertEquals(admin.calls.map((c) => c.fn), ["increment_feature_usage"]);
});

Deno.test("supabaseUsageCounter refunds only a charge that landed, and only once", async () => {
  const admin = fakeQuotaAdmin();
  const counter = supabaseUsageCounter(admin.client, "u1", "tryon_video");
  await counter.charge();
  await counter.refund();
  await counter.refund(); // second refund is a no-op
  assertEquals(admin.calls.map((c) => c.fn), [
    "increment_feature_usage",
    "decrement_feature_usage",
  ]);
  assertEquals(admin.calls[1].args, {
    p_user_id: "u1",
    p_feature_name: "tryon_video",
  });
});
