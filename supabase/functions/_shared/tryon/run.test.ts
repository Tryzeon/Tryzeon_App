import { assertEquals, assertRejects } from "jsr:@std/assert";
import { runTryonJob } from "./run.ts";
import { GenerationFailedError, MissingAvatarError } from "./errors.ts";
import { type DailyUsage, QuotaExceededError } from "../quota.ts";
import type { SupabaseClient } from "jsr:@supabase/supabase-js@2";
import type { QuotaFactory, TryonMode, TryonParams } from "./types.ts";

const USAGE: DailyUsage = {
  user_id: "u1",
  usage_date: "2026-07-26",
  tryon_count: 1,
  chat_count: 0,
  video_count: 0,
};

// The job never reaches Supabase in these tests — quota and every resolver go
// through a port — so an empty object is an honest stand-in for the one client
// it now takes.
const client = {} as unknown as SupabaseClient;

/**
 * Fake `UsageCounter` recording the charge/refund sequence and the mode it was
 * opened with, with a scripted allow/reject.
 */
function fakeQuota(allowed = true) {
  const calls: string[] = [];
  const modes: TryonMode[] = [];
  const factory: QuotaFactory = (_userId, mode) => {
    modes.push(mode);
    return {
      charge() {
        calls.push("charge");
        return Promise.resolve({ allowed, usage: USAGE });
      },
      refund() {
        calls.push("refund");
        return Promise.resolve();
      },
    };
  };
  return { factory, calls, modes };
}

const imageParams: TryonParams = {
  userId: "u1",
  avatar: { base64: "AVATAR" },
  garments: [{ images: [{ base64: "GARMENT" }] }],
  mode: "image",
};

Deno.test("image mode uploads the generated image and does not call video", async () => {
  const quota = fakeQuota();
  let videoCalled = false;
  let uploadedKey = "";
  const result = await runTryonJob(client, imageParams, {
    quota: quota.factory,
    generate: () => Promise.resolve("GENERATEDB64"),
    upload: (_bytes, fileName) => {
      uploadedKey = fileName;
      return Promise.resolve("https://img/result.png");
    },
    generateVideo: () => {
      videoCalled = true;
      return Promise.resolve(new Uint8Array());
    },
    now: () => 123,
  });
  assertEquals(result, {
    kind: "image",
    imageUrl: "https://img/result.png",
    usage: USAGE,
  });
  assertEquals(uploadedKey, "u1/tryon-123.jpg");
  assertEquals(videoCalled, false);
  assertEquals(quota.calls, ["charge"]);
  assertEquals(quota.modes, ["image"]);
});

Deno.test("video mode uploads the generated video bytes, not an image", async () => {
  const quota = fakeQuota();
  let imageUploadCalled = false;
  let uploadedKey = "";
  let uploadedBytes: number[] = [];
  const result = await runTryonJob(
    client,
    { ...imageParams, mode: "video", transitionPrompt: "spin" },
    {
      quota: quota.factory,
      generate: () => Promise.resolve("GENERATEDB64"),
      upload: () => {
        imageUploadCalled = true;
        return Promise.resolve("https://img/should-not-happen.png");
      },
      generateVideo: () => Promise.resolve(new Uint8Array([1, 2, 3])),
      uploadVideo: (bytes, fileName) => {
        uploadedBytes = Array.from(bytes);
        uploadedKey = fileName;
        return Promise.resolve("https://vid/x.mp4");
      },
      now: () => 456,
    },
  );
  assertEquals(result, {
    kind: "video",
    videoUrl: "https://vid/x.mp4",
    usage: USAGE,
  });
  assertEquals(uploadedKey, "u1/tryon-456.mp4");
  assertEquals(uploadedBytes, [1, 2, 3]);
  assertEquals(imageUploadCalled, false);
});

Deno.test("video mode opens the quota counter for the video feature", async () => {
  const quota = fakeQuota();
  await runTryonJob(client, { ...imageParams, mode: "video" }, {
    quota: quota.factory,
    generate: () => Promise.resolve("GENERATEDB64"),
    generateVideo: () => Promise.resolve(new Uint8Array([1])),
    uploadVideo: () => Promise.resolve("https://vid/x.mp4"),
    now: () => 1,
  });
  assertEquals(quota.modes, ["video"]);
});

Deno.test("video mode passes the transition prompt to the generator", async () => {
  const quota = fakeQuota();
  let seenPrompt: string | undefined;
  await runTryonJob(
    client,
    { ...imageParams, mode: "video", transitionPrompt: "spin" },
    {
      quota: quota.factory,
      generate: () => Promise.resolve("GENERATEDB64"),
      generateVideo: (_image, transitionPrompt) => {
        seenPrompt = transitionPrompt;
        return Promise.resolve(new Uint8Array([1]));
      },
      uploadVideo: () => Promise.resolve("https://vid/x.mp4"),
      now: () => 1,
    },
  );
  assertEquals(seenPrompt, "spin");
});

Deno.test("the job runs on validated params, not the raw input", async () => {
  const quota = fakeQuota();
  let seenAvatar = "";
  await runTryonJob(
    client,
    {
      ...imageParams,
      // A blank second key survives the wire but must not reach the loader.
      avatar: { base64: "AVATAR", path: "" } as unknown as TryonParams["avatar"],
    },
    {
      quota: quota.factory,
      generate: (avatarBase64) => {
        seenAvatar = avatarBase64;
        return Promise.resolve("GENERATEDB64");
      },
      upload: () => Promise.resolve("https://img/result.png"),
      now: () => 1,
    },
  );
  assertEquals(seenAvatar, "AVATAR");
});

Deno.test("invalid params are rejected before quota is charged", async () => {
  const quota = fakeQuota();
  await assertRejects(
    () =>
      runTryonJob(client, { ...imageParams, garments: [] }, {
        quota: quota.factory,
      }),
    Error,
  );
  assertEquals(quota.calls, []);
});

Deno.test("quota rejection throws QuotaExceededError with usage", async () => {
  const quota = fakeQuota(false);
  const err = await assertRejects(
    () => runTryonJob(client, imageParams, { quota: quota.factory }),
    QuotaExceededError,
  );
  assertEquals(err.usage, USAGE);
});

Deno.test("null generation throws GenerationFailedError and refunds quota", async () => {
  const quota = fakeQuota();
  await assertRejects(
    () =>
      runTryonJob(client, imageParams, {
        quota: quota.factory,
        generate: () => Promise.resolve(null),
      }),
    GenerationFailedError,
  );
  assertEquals(quota.calls, ["charge", "refund"]);
});

Deno.test("a failed refund does not mask the original error", async () => {
  // Refund throws on top of the real failure; the caller must still see the
  // failure that actually caused the job to abort.
  const quota: QuotaFactory = () => ({
    charge: () => Promise.resolve({ allowed: true, usage: USAGE }),
    refund: () => Promise.reject(new Error("refund exploded")),
  });

  const err = await assertRejects(
    () =>
      runTryonJob(client, imageParams, {
        quota,
        generate: () => Promise.resolve(null),
      }),
    GenerationFailedError,
  );
  assertEquals(err.message, "image generation returned null");
});

Deno.test("an omitted avatar is resolved from the user's profile", async () => {
  const quota = fakeQuota();
  const resolvedFor: string[] = [];
  let seenAvatar = "";
  await runTryonJob(client, { ...imageParams, avatar: undefined }, {
    quota: quota.factory,
    resolveAvatar: (_admin, userId) => {
      resolvedFor.push(userId);
      // Base64 rather than a path: the loader would otherwise reach for storage
      // through the stand-in client.
      return Promise.resolve({ base64: "STORED" });
    },
    generate: (avatarBase64) => {
      seenAvatar = avatarBase64;
      return Promise.resolve("GENERATEDB64");
    },
    upload: () => Promise.resolve("https://img/result.png"),
    now: () => 123,
  });
  assertEquals(resolvedFor, ["u1"]);
  assertEquals(seenAvatar, "STORED");
});

Deno.test("an inline avatar override skips profile resolution", async () => {
  const quota = fakeQuota();
  let resolverCalled = false;
  let seenAvatar = "";
  await runTryonJob(client, imageParams, {
    quota: quota.factory,
    resolveAvatar: () => {
      resolverCalled = true;
      return Promise.resolve({ base64: "STORED" });
    },
    generate: (avatarBase64) => {
      seenAvatar = avatarBase64;
      return Promise.resolve("GENERATEDB64");
    },
    upload: () => Promise.resolve("https://img/result.png"),
    now: () => 123,
  });
  assertEquals(resolverCalled, false);
  assertEquals(seenAvatar, "AVATAR");
});

Deno.test("a user with no stored avatar is never charged", async () => {
  const quota = fakeQuota();
  await assertRejects(
    () =>
      runTryonJob(client, { ...imageParams, avatar: undefined }, {
        quota: quota.factory,
        resolveAvatar: () => Promise.reject(new MissingAvatarError("none")),
        generate: () => Promise.resolve("GENERATEDB64"),
        upload: () => Promise.resolve("https://img/result.png"),
      }),
    MissingAvatarError,
  );
  // Not charge-then-refund: having no photo is a precondition, not a failed job.
  assertEquals(quota.calls, []);
});

Deno.test("product-ref garments are resolved before loading", async () => {
  const quota = fakeQuota();
  const seenGarmentB64: string[] = [];
  const result = await runTryonJob(
    client,
    {
      userId: "u1",
      avatar: { base64: "AVATAR" },
      garments: [{ productId: "11111111-1111-1111-1111-111111111111" }],
      mode: "image",
    },
    {
      quota: quota.factory,
      resolveProduct: () =>
        Promise.resolve({ images: [{ base64: "PRODUCTB64" }], detail: "Product: X" }),
      generate: (_avatar, garmentGroups) => {
        seenGarmentB64.push(...garmentGroups.flat());
        return Promise.resolve("GENERATEDB64");
      },
      upload: () => Promise.resolve("https://img/result.png"),
      now: () => 123,
    },
  );
  assertEquals(result.kind, "image");
  assertEquals(seenGarmentB64, ["PRODUCTB64"]);
});

Deno.test("resolved product detail reaches the generator", async () => {
  const quota = fakeQuota();
  let seenDetails: (string | undefined)[] | undefined;
  await runTryonJob(
    client,
    {
      userId: "u1",
      avatar: { base64: "AVATAR" },
      garments: [{ productId: "11111111-1111-1111-1111-111111111111" }],
      mode: "image",
    },
    {
      quota: quota.factory,
      resolveProduct: () =>
        Promise.resolve({ images: [{ base64: "P" }], detail: "Product: X" }),
      generate: (_avatar, _groups, _scene, garmentDetails) => {
        seenDetails = garmentDetails;
        return Promise.resolve("GENERATEDB64");
      },
      upload: () => Promise.resolve("https://img/result.png"),
      now: () => 123,
    },
  );
  assertEquals(seenDetails, ["Product: X"]);
});

Deno.test("product resolution failure refunds quota", async () => {
  const quota = fakeQuota();
  await assertRejects(
    () =>
      runTryonJob(
        client,
        {
          userId: "u1",
          avatar: { base64: "AVATAR" },
          garments: [{ productId: "bad" }],
          mode: "image",
        },
        {
          quota: quota.factory,
          resolveProduct: () => Promise.reject(new Error("no product")),
        },
      ),
    Error,
  );
  assertEquals(quota.calls, ["charge", "refund"]);
});

Deno.test("a wardrobe ref is resolved with the job's own user id", async () => {
  const quota = fakeQuota();
  const seen: Array<[string, string]> = [];
  const seenGarmentB64: string[] = [];
  await runTryonJob(
    client,
    {
      userId: "u1",
      avatar: { base64: "AVATAR" },
      garments: [{ wardrobeItemId: "44444444-4444-4444-4444-444444444444" }],
      mode: "image",
    },
    {
      quota: quota.factory,
      resolveWardrobe: (_admin, userId, itemId) => {
        // The user id comes from the job, never from the caller's garment —
        // that is what makes the ownership bound unforgeable.
        seen.push([userId, itemId]);
        return Promise.resolve({
          images: [{ base64: "WARDROBEB64" }],
          detail: "Category: top",
        });
      },
      generate: (_avatar, garmentGroups) => {
        seenGarmentB64.push(...garmentGroups.flat());
        return Promise.resolve("GENERATEDB64");
      },
      upload: () => Promise.resolve("https://img/result.png"),
      now: () => 123,
    },
  );

  assertEquals(seen, [["u1", "44444444-4444-4444-4444-444444444444"]]);
  assertEquals(seenGarmentB64, ["WARDROBEB64"]);
});

Deno.test("each garment kind reaches its own resolver", async () => {
  const quota = fakeQuota();
  let productCalls = 0;
  let wardrobeCalls = 0;
  const seenGarmentB64: string[] = [];
  await runTryonJob(
    client,
    {
      userId: "u1",
      avatar: { base64: "AVATAR" },
      garments: [
        { productId: "11111111-1111-1111-1111-111111111111" },
        { wardrobeItemId: "44444444-4444-4444-4444-444444444444" },
        { images: [{ base64: "RAWB64" }] },
      ],
      mode: "image",
    },
    {
      quota: quota.factory,
      resolveProduct: () => {
        productCalls++;
        return Promise.resolve({ images: [{ base64: "PRODUCTB64" }] });
      },
      resolveWardrobe: () => {
        wardrobeCalls++;
        return Promise.resolve({ images: [{ base64: "WARDROBEB64" }] });
      },
      generate: (_avatar, garmentGroups) => {
        seenGarmentB64.push(...garmentGroups.flat());
        return Promise.resolve("GENERATEDB64");
      },
      upload: () => Promise.resolve("https://img/result.png"),
      now: () => 123,
    },
  );

  assertEquals([productCalls, wardrobeCalls], [1, 1]);
  // Order preserved, and caller-supplied material still passes through untouched.
  assertEquals(seenGarmentB64, ["PRODUCTB64", "WARDROBEB64", "RAWB64"]);
});
