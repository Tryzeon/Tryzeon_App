import { assertEquals, assertStringIncludes } from "jsr:@std/assert";
import { type RouterDeps, routeEvent } from "./router.ts";
import type { LineApi } from "./line-api.ts";
import { fakeConversations } from "./conversation.testing.ts";
import { productTryonPostbackData, wardrobeTryonPostbackData } from "./postback.ts";

const line: LineApi = {
  reply: () => Promise.resolve(),
  push: () => Promise.resolve(),
  getContent: () => Promise.resolve(new Uint8Array()),
  showLoading: () => Promise.resolve(),
  getDisplayName: () => Promise.resolve(undefined),
};

const deps: RouterDeps = {
  // deno-lint-ignore no-explicit-any
  admin: {} as any,
  line,
  liffUrl: "https://liff.example",
  imagesBaseUrl: "https://img.example",
  conversations: fakeConversations().store,
};

const PID = "8f14e45f-ceea-467a-9c8d-1b2c3d4e5f60";
const WID = "44444444-4444-4444-4444-444444444444";

const messageEvent = (message: Record<string, unknown>) => ({
  type: "message",
  replyToken: "rt",
  source: { type: "user", userId: "Uline123" },
  message,
});

const postbackEvent = (data: unknown) => ({
  type: "postback",
  replyToken: "rt",
  source: { type: "user", userId: "Uline123" },
  postback: { data },
});

/**
 * The handlers are not stubbed: routing is asserted by whether a task comes
 * back, so a started task is swallowed rather than awaited.
 */
const routed = (ev: Record<string, unknown>) => {
  const task = routeEvent(deps, ev);
  task?.catch(() => {});
  return task !== null;
};

/**
 * `routed` cannot tell an event answered by a fixed message from one a handler
 * took — both come back as a task — so this asserts the difference by the reply.
 */
async function repliedWith(ev: Record<string, unknown>): Promise<object[]> {
  const sent: object[][] = [];
  const recording: LineApi = {
    ...line,
    reply: (_token, messages) => {
      sent.push(messages);
      return Promise.resolve();
    },
  };

  await routeEvent({ ...deps, line: recording }, ev)?.catch(() => {});
  return sent[0] ?? [];
}

// deno-lint-ignore no-explicit-any
const textOf = (message: object) => (message as any).text as string;

Deno.test("an image is routed to a handler", () => {
  assertEquals(routed(messageEvent({ type: "image", id: "m1" })), true);
});

Deno.test("text is routed to a handler", () => {
  assertEquals(routed(messageEvent({ type: "text", text: "找白襯衫" })), true);
});

Deno.test("whitespace-only text is nudged, not answered", async () => {
  for (const message of [{ type: "text", text: "   \n " }, { type: "text", text: "" }, { type: "text" }]) {
    assertStringIncludes(textOf((await repliedWith(messageEvent(message)))[0]), "傳一張衣服的照片");
  }
});

Deno.test("a message kind with no handler is nudged", async () => {
  // Understood the sender well enough to know we cannot act on it — a different
  // thing from the event not being a request; see the `unsend` test.
  assertStringIncludes(
    textOf((await repliedWith(messageEvent({ type: "sticker", id: "s1" })))[0]),
    "傳一張衣服的照片",
  );
  assertStringIncludes(
    textOf((await repliedWith(messageEvent({ type: "audio", id: "a1" })))[0]),
    "傳一張衣服的照片",
  );
});

Deno.test("a try-on postback is routed to a handler", () => {
  assertEquals(routed(postbackEvent(`a=tryon_product&pid=${PID}`)), true);
});

Deno.test("a postback we did not issue is nudged", async () => {
  // The sender tapped something real, so silence would read as the bot being
  // broken.
  for (
    const data of [
      "a=save&pid=" + PID,
      "a=tryon_product&pid=not-a-uuid",
      "a=tryon&pid=" + PID,
      undefined,
    ]
  ) {
    assertStringIncludes(textOf((await repliedWith(postbackEvent(data)))[0]), "傳一張衣服的照片");
  }
});

Deno.test("an event kind this module does not route returns nothing", () => {
  assertEquals(routed({ type: "unsend", source: { userId: "U1" } }), false);
  assertEquals(routed({ type: "join", replyToken: "rt", source: { userId: "U1" } }), false);
});

Deno.test("a new follower is greeted on the reply token", async () => {
  const sent: { token: string; messages: object[] }[] = [];
  const recording: LineApi = {
    ...line,
    reply: (token, messages) => {
      sent.push({ token, messages });
      return Promise.resolve();
    },
  };

  await routeEvent({ ...deps, line: recording }, {
    type: "follow",
    replyToken: "rt",
    source: { type: "user", userId: "Uline123" },
  });

  assertEquals(sent.length, 1);
  assertEquals(sent[0].token, "rt");
  // deno-lint-ignore no-explicit-any
  assertStringIncludes((sent[0].messages[0] as any).text, "Tryzeon");
});

Deno.test("a follower LINE will not name is greeted anyway", () => {
  assertEquals(routed({ type: "follow", replyToken: "rt", source: { type: "user" } }), true);
});

Deno.test("an event with no source.userId reaches no handler", async () => {
  // LINE omits `source.userId` when the sender has not consented to the OA Terms
  // of Use. Handling it anyway would key the conversation store on the literal
  // string "undefined", pooling every such sender's transcript into one bucket.
  const noId = { type: "user" };

  assertStringIncludes(
    textOf((await repliedWith({
      type: "message",
      replyToken: "rt",
      source: noId,
      message: { type: "text", text: "hi" },
    }))[0]),
    "傳一張衣服的照片",
  );
  assertStringIncludes(
    textOf((await repliedWith({
      type: "postback",
      replyToken: "rt",
      source: noId,
      postback: { data: productTryonPostbackData(PID) },
    }))[0]),
    "傳一張衣服的照片",
  );
});

Deno.test("a group is not somewhere this feature answers", () => {
  // Nothing here has an answer for a group yet, and pushing a try-on of
  // someone's body into one would be the wrong first attempt at having one.
  assertEquals(
    routed({
      type: "message",
      replyToken: "rt",
      source: { type: "group", groupId: "G1", userId: "Uline123" },
      message: { type: "text", text: "找白襯衫" },
    }),
    false,
  );
});

Deno.test("a wardrobe try-on postback is routed to a handler", () => {
  assertEquals(routed(postbackEvent(wardrobeTryonPostbackData(WID))), true);
});

Deno.test("a wardrobe postback with no sender is nudged", async () => {
  assertStringIncludes(
    textOf((await repliedWith({
      type: "postback",
      replyToken: "rt",
      source: { type: "user" },
      postback: { data: wardrobeTryonPostbackData(WID) },
    }))[0]),
    "傳一張衣服的照片",
  );
});
