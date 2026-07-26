// The charge/refund semantics belong to `supabaseQuotaPort` and are tested in
// `_shared/quota.test.ts`. What is chat's — and all that is asserted here — is
// which counter it charges.
import { assertEquals } from "jsr:@std/assert";
import { supabaseChatQuota } from "./quota.ts";
import { fakeQuotaAdmin, SAMPLE_USAGE } from "../quota.testing.ts";

Deno.test("supabaseChatQuota charges the chat feature", async () => {
  const admin = fakeQuotaAdmin();
  const result = await supabaseChatQuota(admin.client, "u1").charge();
  assertEquals(result, { allowed: true, usage: SAMPLE_USAGE });
  assertEquals(admin.calls, [{
    fn: "increment_feature_usage",
    args: { p_user_id: "u1", p_feature_name: "chat" },
  }]);
});
