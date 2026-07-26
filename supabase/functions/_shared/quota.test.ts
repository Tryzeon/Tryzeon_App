import { assertEquals } from "jsr:@std/assert";
import { supabaseQuotaPort } from "./quota.ts";
import { fakeQuotaAdmin, SAMPLE_USAGE } from "./quota.testing.ts";

Deno.test("supabaseQuotaPort charges the named feature and echoes the usage row", async () => {
  const admin = fakeQuotaAdmin();
  const result = await supabaseQuotaPort(admin.client, "u1", "chat").charge();
  assertEquals(result, { allowed: true, usage: SAMPLE_USAGE });
  assertEquals(admin.calls, [{
    fn: "increment_feature_usage",
    args: { p_user_id: "u1", p_feature_name: "chat" },
  }]);
});

Deno.test("supabaseQuotaPort reports a rejection without refunding", async () => {
  const admin = fakeQuotaAdmin(false);
  const port = supabaseQuotaPort(admin.client, "u1", "tryon");
  assertEquals((await port.charge()).allowed, false);
  await port.refund();
  assertEquals(admin.calls.map((c) => c.fn), ["increment_feature_usage"]);
});

Deno.test("supabaseQuotaPort refunds only a charge that landed, and only once", async () => {
  const admin = fakeQuotaAdmin();
  const port = supabaseQuotaPort(admin.client, "u1", "tryon_video");
  await port.charge();
  await port.refund();
  await port.refund(); // second refund is a no-op
  assertEquals(admin.calls.map((c) => c.fn), [
    "increment_feature_usage",
    "decrement_feature_usage",
  ]);
  assertEquals(admin.calls[1].args, {
    p_user_id: "u1",
    p_feature_name: "tryon_video",
  });
});
