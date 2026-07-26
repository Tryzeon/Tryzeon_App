import { assertEquals } from "jsr:@std/assert";
import { supabaseQuota } from "./quota.ts";
import type { DailyUsage } from "../quota.ts";
import type { TryonClients } from "./types.ts";

const USAGE: DailyUsage = {
  user_id: "u1",
  usage_date: "2026-07-26",
  tryon_count: 1,
  chat_count: 0,
  video_count: 0,
};

/** Records every RPC the port issues, with the arguments it passed. */
function fakeAdmin(allowed = true) {
  const calls: Array<{ fn: string; args: Record<string, unknown> }> = [];
  const client = {
    rpc(fn: string, args: Record<string, unknown>) {
      calls.push({ fn, args });
      if (fn === "increment_feature_usage") {
        return Promise.resolve({
          data: { allowed, usage: USAGE },
          error: null,
        });
      }
      return Promise.resolve({ data: true, error: null });
    },
  } as unknown as TryonClients["admin"];
  return { client, calls };
}

Deno.test("supabaseQuota charges the image feature for image mode", async () => {
  const admin = fakeAdmin();
  const result = await supabaseQuota(admin.client, "u1", "image").charge();
  assertEquals(result.allowed, true);
  assertEquals(result.usage, USAGE);
  assertEquals(admin.calls, [{
    fn: "increment_feature_usage",
    args: { p_user_id: "u1", p_feature_name: "tryon" },
  }]);
});

Deno.test("supabaseQuota charges the video feature for video mode", async () => {
  const admin = fakeAdmin();
  await supabaseQuota(admin.client, "u1", "video").charge();
  assertEquals(admin.calls[0].args.p_feature_name, "tryon_video");
});

Deno.test("supabaseQuota reports a rejection without refunding", async () => {
  const admin = fakeAdmin(false);
  const port = supabaseQuota(admin.client, "u1", "image");
  assertEquals((await port.charge()).allowed, false);
  await port.refund();
  assertEquals(admin.calls.map((c) => c.fn), ["increment_feature_usage"]);
});

Deno.test("supabaseQuota refunds only a charge that landed", async () => {
  const admin = fakeAdmin();
  const port = supabaseQuota(admin.client, "u1", "video");
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
