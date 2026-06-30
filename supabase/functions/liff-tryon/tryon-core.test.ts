// supabase/functions/liff-tryon/tryon-core.test.ts
import { assertEquals, assertRejects } from "jsr:@std/assert";
import {
  GenerationFailedError,
  QuotaExceededError,
  runTryon,
} from "./tryon-core.ts";

// Fake admin exposing only `.rpc`, which is all QuotaManager touches.
function makeQuotaAdmin(allowed: boolean) {
  const rpcCalls: string[] = [];
  // deno-lint-ignore no-explicit-any
  const admin: any = {
    rpc(name: string, _args: unknown) {
      rpcCalls.push(name);
      if (name === "increment_feature_usage") {
        return Promise.resolve({ data: { allowed, usage: { tryon_count: 1 } }, error: null });
      }
      if (name === "decrement_feature_usage") {
        return Promise.resolve({ data: true, error: null });
      }
      return Promise.resolve({ data: null, error: null });
    },
  };
  return { admin, rpcCalls };
}

Deno.test("runTryon returns imageUrl + usage on success", async () => {
  const { admin } = makeQuotaAdmin(true);
  const result = await runTryon(admin, "uid", "avatar64", "stores/demo/x.jpg", {
    fetchImage: () => Promise.resolve("garment64"),
    generate: () => Promise.resolve("R0lGODdh"), // any base64-ish payload
    upload: () => Promise.resolve("https://r2.example/result.jpg"),
  });
  assertEquals(result.imageUrl, "https://r2.example/result.jpg");
  assertEquals(result.usage, { tryon_count: 1 });
});

Deno.test("runTryon throws QuotaExceededError when quota rejects", async () => {
  const { admin, rpcCalls } = makeQuotaAdmin(false);
  await assertRejects(
    () =>
      runTryon(admin, "uid", "a", "stores/demo/x.jpg", {
        fetchImage: () => Promise.resolve("g"),
        generate: () => Promise.resolve("img"),
        upload: () => Promise.resolve("url"),
      }),
    QuotaExceededError,
  );
  // No rollback when never incremented.
  assertEquals(rpcCalls.includes("decrement_feature_usage"), false);
});

Deno.test("runTryon rolls back quota when generation returns null", async () => {
  const { admin, rpcCalls } = makeQuotaAdmin(true);
  await assertRejects(
    () =>
      runTryon(admin, "uid", "a", "stores/demo/x.jpg", {
        fetchImage: () => Promise.resolve("g"),
        generate: () => Promise.resolve(null),
        upload: () => Promise.resolve("url"),
      }),
    GenerationFailedError,
  );
  assertEquals(rpcCalls.includes("decrement_feature_usage"), true);
});
