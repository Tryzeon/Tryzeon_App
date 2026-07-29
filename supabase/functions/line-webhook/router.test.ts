import { assertEquals, assertStringIncludes } from "jsr:@std/assert";
import { type RouterDeps, routeEvent } from "./router.ts";
import type { LineApi } from "./line-api.ts";
import { fakeConversations } from "./conversation.testing.ts";

const line: LineApi = {
  reply: () => Promise.resolve(),
  push: () => Promise.resolve(),
  getContent: () => Promise.resolve(new Uint8Array()),
  showLoading: () => Promise.resolve(),
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
 * back at all, so a started task is swallowed rather than awaited. That keeps
 * the assertion on the routing decision, which is what this module owns.
 */
const routed = (ev: Record<string, unknown>) => {
  const task = routeEvent(deps, ev);
  task?.catch(() => {});
  return task !== null;
};

Deno.test("an image is routed to a handler", () => {
  assertEquals(routed(messageEvent({ type: "image", id: "m1" })), true);
});

Deno.test("text is routed to a handler", () => {
  assertEquals(routed(messageEvent({ type: "text", text: "找白襯衫" })), true);
});

Deno.test("whitespace-only text is not a request", () => {
  assertEquals(routed(messageEvent({ type: "text", text: "   \n " })), false);
  assertEquals(routed(messageEvent({ type: "text", text: "" })), false);
  assertEquals(routed(messageEvent({ type: "text" })), false);
});

Deno.test("a message kind with no handler routes nowhere", () => {
  assertEquals(routed(messageEvent({ type: "sticker", id: "s1" })), false);
  assertEquals(routed(messageEvent({ type: "audio", id: "a1" })), false);
});

Deno.test("a try-on postback is routed to a handler", () => {
  assertEquals(routed(postbackEvent(`a=tryon&pid=${PID}`)), true);
});

Deno.test("a postback we did not issue routes nowhere", () => {
  assertEquals(routed(postbackEvent("a=save&pid=" + PID)), false);
  assertEquals(routed(postbackEvent("a=tryon&pid=not-a-uuid")), false);
  assertEquals(routed(postbackEvent(undefined)), false);
  assertEquals(routed({ type: "postback", replyToken: "rt", source: { userId: "U1" } }), false);
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
  // The one event that needs no `source.userId`: nothing is read, written or
  // charged, so someone who has not accepted the OA's terms still gets it.
  assertEquals(routed({ type: "follow", replyToken: "rt", source: { type: "user" } }), true);
});

Deno.test("an event with no source.userId routes nowhere", () => {
  // LINE omits `source.userId` when the sender has not consented to the OA
  // Terms of Use. Routing it anyway would key the conversation store on the
  // literal string "undefined", pooling every such sender's transcript into
  // one bucket — so every event that reaches the store or the quota is dropped
  // here rather than left as a downstream concern for each handler. A follow
  // touches neither, which is why it is greeted regardless (see above).
  assertEquals(
    routed({ type: "message", replyToken: "rt", source: { type: "user" }, message: { type: "text", text: "hi" } }),
    false,
  );
  assertEquals(
    routed({ type: "postback", replyToken: "rt", source: { type: "user" }, postback: { data: `a=tryon&pid=${PID}` } }),
    false,
  );
});
