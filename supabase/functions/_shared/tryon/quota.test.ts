import { assertEquals } from "jsr:@std/assert";
import { supabaseQuota } from "./quota.ts";
import { fakeQuotaAdmin, SAMPLE_USAGE } from "../quota.testing.ts";

Deno.test("supabaseQuota charges the image feature for image mode", async () => {
  const admin = fakeQuotaAdmin();
  const result = await supabaseQuota(admin.client)("u1", "image").charge();
  assertEquals(result, { allowed: true, usage: SAMPLE_USAGE });
  assertEquals(admin.calls, [{
    fn: "increment_feature_usage",
    args: { p_user_id: "u1", p_feature_name: "tryon" },
  }]);
});

Deno.test("supabaseQuota charges the video feature for video mode", async () => {
  const admin = fakeQuotaAdmin();
  await supabaseQuota(admin.client)("u1", "video").charge();
  assertEquals(admin.calls[0].args.p_feature_name, "tryon_video");
});
