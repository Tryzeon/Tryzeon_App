import { assertEquals } from "jsr:@std/assert";
import { type RouterDeps, routeMessageEvent } from "./router.ts";
import type { LineApi } from "./line-api.ts";

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
  liffOnboardUrl: "https://liff.example/onboard",
  imagesBaseUrl: "https://img.example",
};

const event = (message: Record<string, unknown>) => ({
  type: "message",
  replyToken: "rt",
  source: { type: "user", userId: "Uline123" },
  message,
});

/**
 * The handlers are not stubbed: routing is asserted by whether a task comes
 * back at all, so a started task is swallowed rather than awaited. That keeps
 * the assertion on the routing decision, which is what this module owns.
 */
const routed = (message: Record<string, unknown>) => {
  const task = routeMessageEvent(deps, event(message));
  task?.catch(() => {});
  return task !== null;
};

Deno.test("an image is routed to a handler", () => {
  assertEquals(routed({ type: "image", id: "m1" }), true);
});

Deno.test("text is routed to a handler", () => {
  assertEquals(routed({ type: "text", text: "找白襯衫" }), true);
});

Deno.test("whitespace-only text is not a request", () => {
  assertEquals(routed({ type: "text", text: "   \n " }), false);
  assertEquals(routed({ type: "text", text: "" }), false);
  assertEquals(routed({ type: "text" }), false);
});

Deno.test("a message kind with no handler routes nowhere", () => {
  assertEquals(routed({ type: "sticker", id: "s1" }), false);
  assertEquals(routed({ type: "audio", id: "a1" }), false);
});
