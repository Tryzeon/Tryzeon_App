import { assertEquals } from "jsr:@std/assert";
import {
  cameraRollChip,
  dressLast,
  messageChip,
  postbackChip,
  uriChip,
  withQuickReply,
} from "./quick-reply.ts";

Deno.test("a message chip carries the label and the words it sends as two strings", () => {
  // What the chip says and what it types on the sender's behalf are different
  // copy: the label is a button, the text has to read like something they said.
  assertEquals(messageChip("便宜一點的", "有便宜一點的嗎"), {
    type: "action",
    action: { type: "message", label: "便宜一點的", text: "有便宜一點的嗎" },
  });
});

Deno.test("a camera roll chip carries no image of its own", () => {
  // LINE supplies the default icon for camera/cameraRoll/location actions when
  // `imageUrl` is omitted, so this is the one chip kind that needs no asset.
  assertEquals(cameraRollChip("再試一件"), {
    type: "action",
    action: { type: "cameraRoll", label: "再試一件" },
  });
});

Deno.test("a postback chip says out loud what was tapped", () => {
  // Without `displayText` the tap leaves no trace and the bot appears to start
  // talking for no reason — the same rule the product card follows.
  assertEquals(postbackChip("再試一次", "a=tryon&pid=p1", "試穿「短版牛仔外套」"), {
    type: "action",
    action: {
      type: "postback",
      label: "再試一次",
      data: "a=tryon&pid=p1",
      displayText: "試穿「短版牛仔外套」",
    },
  });
});

Deno.test("a uri chip carries the link it opens", () => {
  assertEquals(uriChip("先逛逛商品", "https://liff.example"), {
    type: "action",
    action: { type: "uri", label: "先逛逛商品", uri: "https://liff.example" },
  });
});

Deno.test("chips are attached without disturbing the message", () => {
  const message = { type: "text", text: "好" };
  const dressed = withQuickReply(message, [cameraRollChip("再試一件")]);

  assertEquals(dressed, {
    type: "text",
    text: "好",
    quickReply: { items: [cameraRollChip("再試一件")] },
  });
  // The original is left alone: message factories return fresh objects, but a
  // helper that mutated its argument would be a trap for the one that doesn't.
  assertEquals(message, { type: "text", text: "好" });
});

Deno.test("no chips means no quickReply property at all", () => {
  // A caller may compute an empty set (an answer that is only a follow-up
  // question). An empty `items` array is not something LINE accepts.
  const message = { type: "text", text: "你想找什麼場合穿的？" };

  assertEquals(withQuickReply(message, []), message);
});

Deno.test("more chips than LINE accepts are cut to the limit", () => {
  const many = Array.from({ length: 20 }, (_, i) => messageChip(`c${i}`, `t${i}`));
  const dressed = withQuickReply({ type: "text", text: "好" }, many) as {
    quickReply: { items: object[] };
  };

  assertEquals(dressed.quickReply.items.length, 13);
  assertEquals(dressed.quickReply.items[0], many[0]);
});

Deno.test("only the last message of a send is dressed", () => {
  // LINE does not document which quick reply wins when several messages in one
  // send carry them, so exactly one ever does.
  const chip = messageChip("便宜一點的", "有便宜一點的嗎");
  const out = dressLast(
    [{ type: "text", text: "為你找到" }, { type: "flex", altText: "3 件" }],
    [chip],
  );

  assertEquals(out[0], { type: "text", text: "為你找到" });
  assertEquals(out[1], {
    type: "flex",
    altText: "3 件",
    quickReply: { items: [chip] },
  });
});

Deno.test("an empty send is left alone rather than dressed into a typeless message", () => {
  // `at(-1)` on an empty array is `undefined`; spreading it would yield an
  // object carrying a `quickReply` and no `type`, which LINE rejects — and it
  // rejects the whole send, not just that message.
  assertEquals(dressLast([], [messageChip("便宜一點的", "有便宜一點的嗎")]), []);
});

Deno.test("no chips leaves every message untouched", () => {
  const messages = [{ type: "text", text: "你想找什麼場合穿的？" }];

  assertEquals(dressLast(messages, []), messages);
});
