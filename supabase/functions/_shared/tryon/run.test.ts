import { assertEquals, assertRejects } from "jsr:@std/assert";
import { runTryonJob } from "./run.ts";
import {
  GenerationFailedError,
  QuotaExceededError,
  type TryonClients,
  type TryonParams,
} from "./types.ts";

// Fake admin client: records which quota RPCs were called and returns a
// scripted allow/reject for increment_feature_usage.
function fakeAdmin(allowed: boolean) {
  const calls: string[] = [];
  const client = {
    rpc(fn: string) {
      calls.push(fn);
      if (fn === "increment_feature_usage") {
        return Promise.resolve({
          data: { allowed, usage: { tryon_count: 1 } },
          error: null,
        });
      }
      // decrement_feature_usage (rollback)
      return Promise.resolve({ data: true, error: null });
    },
  };
  return { client: client as unknown as TryonClients["admin"], calls };
}

const imageParams: TryonParams = {
  userId: "u1",
  avatar: { base64: "AVATAR" },
  garments: [{ images: [{ base64: "GARMENT" }] }],
  mode: "image",
};

Deno.test("image mode returns imageUrl and does not call video", async () => {
  const { client } = fakeAdmin(true);
  let videoCalled = false;
  const result = await runTryonJob({ admin: client }, imageParams, {
    generate: () => Promise.resolve("GENERATEDB64"),
    upload: () => Promise.resolve("https://img/result.png"),
    generateVideo: () => {
      videoCalled = true;
      return Promise.resolve("https://vid/x.mp4");
    },
    now: () => 123,
  });
  assertEquals(result, {
    kind: "image",
    imageUrl: "https://img/result.png",
    usage: { tryon_count: 1 },
  });
  assertEquals(videoCalled, false);
});

Deno.test("video mode returns videoUrl and does not upload an image", async () => {
  const { client } = fakeAdmin(true);
  let uploadCalled = false;
  const result = await runTryonJob(
    { admin: client },
    { ...imageParams, mode: "video", transitionPrompt: "spin" },
    {
      generate: () => Promise.resolve("GENERATEDB64"),
      upload: () => {
        uploadCalled = true;
        return Promise.resolve("https://img/should-not-happen.png");
      },
      generateVideo: () => Promise.resolve("https://vid/x.mp4"),
    },
  );
  assertEquals(result, {
    kind: "video",
    videoUrl: "https://vid/x.mp4",
    usage: { tryon_count: 1 },
  });
  assertEquals(uploadCalled, false);
});

Deno.test("quota rejection throws QuotaExceededError with usage", async () => {
  const { client } = fakeAdmin(false);
  const err = await assertRejects(
    () => runTryonJob({ admin: client }, imageParams),
    QuotaExceededError,
  );
  assertEquals(err.usage, { tryon_count: 1 });
});

Deno.test("null generation throws GenerationFailedError and rolls back quota", async () => {
  const { client, calls } = fakeAdmin(true);
  await assertRejects(
    () =>
      runTryonJob({ admin: client }, imageParams, {
        generate: () => Promise.resolve(null),
      }),
    GenerationFailedError,
  );
  assertEquals(calls.includes("decrement_feature_usage"), true);
});
