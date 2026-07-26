import { assertEquals, assertThrows } from "jsr:@std/assert";
import { parseChatParams } from "./request.ts";
import { ValidationError } from "../_shared/chat/index.ts";
import type { ChatMessage } from "../_shared/chat/index.ts";

const body = (value: unknown) => JSON.stringify(value);

Deno.test("parseChatParams shapes the wire body and attaches userId", () => {
  const messages: ChatMessage[] = [
    { role: "user", content: [{ type: "text", text: "找白襯衫" }] },
  ];
  assertEquals(parseChatParams(body({ messages }), "u1"), {
    userId: "u1",
    messages,
  });
});

Deno.test("parseChatParams rejects unparseable JSON as a validation error", () => {
  assertThrows(
    () => parseChatParams("{not json", "u1"),
    ValidationError,
    "body must be valid JSON",
  );
});

Deno.test("parseChatParams rejects an empty body", () => {
  assertThrows(() => parseChatParams("", "u1"), ValidationError);
});

Deno.test("parseChatParams rejects a non-object body", () => {
  assertThrows(
    () => parseChatParams(body([1, 2]), "u1"),
    ValidationError,
    "messages must be an array",
  );
  assertThrows(
    () => parseChatParams(body(null), "u1"),
    ValidationError,
    "body must be an object",
  );
});

Deno.test("parseChatParams rejects a non-array messages field", () => {
  assertThrows(
    () => parseChatParams(body({ messages: "hi" }), "u1"),
    ValidationError,
    "messages must be an array",
  );
});

Deno.test("parseChatParams defers invariants to the core", () => {
  // Empty history, an unknown role and junk content all survive decoding —
  // validateChatParams is the single guard that rejects them.
  const messages = [{ role: "system", content: "nope" }];
  assertEquals(parseChatParams(body({ messages }), "u1").messages, messages as never);
  assertEquals(parseChatParams(body({ messages: [] }), "u1").messages, []);
});

Deno.test("parseChatParams never invents an onEvent sink", () => {
  const params = parseChatParams(body({ messages: [] }), "u1");
  assertEquals(params.onEvent, undefined);
});
