import { assertEquals, assertStringIncludes } from "jsr:@std/assert";
import { type ChatHandlerDeps, handleTextMessage } from "./chat-handler.ts";
import {
  type ChatParams,
  type ContentBlock,
  LIMITS,
  type RunChatAgentDeps,
  runChatAgent,
} from "../_shared/chat/index.ts";
import { QuotaExceededError } from "../_shared/quota.ts";
import { ValidationError } from "../_shared/validation.ts";
import type { LineApi } from "./line-api.ts";
import type { ChatMessage } from "../_shared/chat/index.ts";
import { fakeConversations } from "./conversation.testing.ts";

const USER = "Uline123";
const PID = "8f14e45f-ceea-467a-9c8d-1b2c3d4e5f60";

/** LINE double recording what was sent, with a scripted `showLoading` outcome. */
function fakeLine(opts: { loadingFails?: boolean } = {}) {
  const pushed: object[][] = [];
  const loading: string[] = [];
  const line: LineApi = {
    reply: () => Promise.resolve(),
    push: (_to, messages) => {
      pushed.push(messages);
      return Promise.resolve();
    },
    getContent: () => Promise.resolve(new Uint8Array()),
    showLoading: (to) => {
      loading.push(to);
      return opts.loadingFails
        ? Promise.reject(new Error("loading down"))
        : Promise.resolve();
    },
  };
  return { line, pushed, loading };
}

/**
 * Chat double returning scripted blocks (or throwing), recording its params.
 *
 * Typed as `runChatAgent` itself, so a rename in `ChatParams` fails the build
 * here rather than leaving the assertions below silently reading `undefined`.
 */
function fakeChat(
  outcome: { blocks: ContentBlock[]; messages?: ChatMessage[] } | { throws: unknown },
) {
  const seen: { params: ChatParams; deps: RunChatAgentDeps }[] = [];
  const runChat: typeof runChatAgent = (_clients, params, deps = {}) => {
    seen.push({ params, deps });
    if ("throws" in outcome) return Promise.reject(outcome.throws);
    return Promise.resolve({
      blocks: outcome.blocks,
      messages: outcome.messages ?? [],
      usage: null,
    });
  };
  return { runChat, seen };
}

function deps(over: Partial<ChatHandlerDeps> = {}): ChatHandlerDeps {
  return {
    // deno-lint-ignore no-explicit-any
    admin: {} as any,
    line: fakeLine().line,
    imagesBaseUrl: "https://img.example",
    conversations: fakeConversations().store,
    getOrCreateUserId: () => Promise.resolve("user-uuid"),
    ...over,
  };
}

const textOf = (message: object) => (message as { text: string }).text;

/** Runs `fn` with `console[method]` silenced, returning what it would have logged. */
async function captureConsole(
  method: "error" | "warn",
  fn: () => Promise<void>,
): Promise<unknown[][]> {
  const real = console[method];
  const calls: unknown[][] = [];
  console[method] = (...args: unknown[]) => {
    calls.push(args);
  };
  try {
    await fn();
  } finally {
    console[method] = real;
  }
  return calls;
}

Deno.test("runs one turn for the incoming message and pushes the answer", async () => {
  const { line, pushed, loading } = fakeLine();
  const chat = fakeChat({ blocks: [{ type: "text", text: "為你找到" }] });

  await handleTextMessage(deps({ line, runChat: chat.runChat }), {
    sourceUserId: USER,
    text: "找白襯衫",
  });

  assertEquals(loading, [USER]);
  // A new conversation: the transcript is this message alone.
  assertEquals(chat.seen[0].params.userId, "user-uuid");
  assertEquals(chat.seen[0].params.messages, [
    { role: "user", content: [{ type: "text", text: "找白襯衫" }] },
  ]);
  assertEquals(pushed, [[{ type: "text", text: "為你找到" }]]);
});

Deno.test("substitutes this channel's hydrator and nothing else", async () => {
  const chat = fakeChat({ blocks: [{ type: "text", text: "好" }] });

  await handleTextMessage(deps({ runChat: chat.runChat }), {
    sourceUserId: USER,
    text: "找白襯衫",
  });

  assertEquals(Object.keys(chat.seen[0].deps), ["hydrate"]);
});

Deno.test("rejects an over-long message before charging anything", async () => {
  const { line, pushed } = fakeLine();
  const chat = fakeChat({ blocks: [] });

  await handleTextMessage(deps({ line, runChat: chat.runChat }), {
    sourceUserId: USER,
    text: "x".repeat(LIMITS.MAX_TEXT_LENGTH + 1),
  });

  assertEquals(chat.seen.length, 0);
  assertStringIncludes(textOf(pushed[0][0]), "太長");
});

Deno.test("reports a spent quota in this channel's words", async () => {
  const { line, pushed } = fakeLine();
  const chat = fakeChat({ throws: new QuotaExceededError(null) });

  await handleTextMessage(deps({ line, runChat: chat.runChat }), {
    sourceUserId: USER,
    text: "找白襯衫",
  });

  assertStringIncludes(textOf(pushed[0][0]), "今日對話次數");
});

Deno.test("reports an unexpected failure as a generic apology", async () => {
  const { line, pushed } = fakeLine();
  const chat = fakeChat({ throws: new Error("vertex exploded") });

  const errors = await captureConsole("error", () =>
    handleTextMessage(deps({ line, runChat: chat.runChat }), {
      sourceUserId: USER,
      text: "找白襯衫",
    }));

  assertStringIncludes(textOf(pushed[0][0]), "稍後再試");
  // A server fault leaves a trace beyond the pushed message.
  assertEquals(errors.length, 1);
});

Deno.test("a failed typing indicator does not cost the caller their answer", async () => {
  const { line, pushed } = fakeLine({ loadingFails: true });
  const chat = fakeChat({ blocks: [{ type: "text", text: "為你找到" }] });

  await captureConsole("warn", () =>
    handleTextMessage(deps({ line, runChat: chat.runChat }), {
      sourceUserId: USER,
      text: "找白襯衫",
    }));

  assertEquals(pushed, [[{ type: "text", text: "為你找到" }]]);
});

Deno.test("the turn runs on the stored conversation plus this message", async () => {
  const prior: ChatMessage[] = [
    { role: "user", content: [{ type: "text", text: "找外套" }] },
    {
      role: "assistant",
      content: [{ type: "text", text: "為你找到" }, { type: "product", id: PID }],
    },
  ];
  const conversations = fakeConversations({ prior });
  const chat = fakeChat({ blocks: [{ type: "text", text: "這件比較便宜" }] });

  await handleTextMessage(
    deps({ runChat: chat.runChat, conversations: conversations.store }),
    { sourceUserId: USER, text: "有便宜一點的嗎" },
  );

  // The follow-up is only answerable because the prior turns went in with it.
  assertEquals(chat.seen[0].params.messages, [
    ...prior,
    { role: "user", content: [{ type: "text", text: "有便宜一點的嗎" }] },
  ]);
});

Deno.test("the whole turn is written back, with recommended items reduced to ids", async () => {
  const conversations = fakeConversations();
  const answer: ChatMessage = {
    role: "assistant",
    content: [
      { type: "text", text: "為你找到" },
      { type: "product", item: { id: PID, name: "短版牛仔外套" } },
    ],
  };
  const chat = fakeChat({
    blocks: answer.content,
    messages: [
      {
        role: "assistant",
        content: [{ type: "tool_use", id: "t1", name: "search_products", input: {} }],
      },
      {
        role: "user",
        content: [{ type: "tool_result", tool_use_id: "t1", content: { items: [] } }],
      },
      answer,
    ],
  });

  await handleTextMessage(
    deps({ runChat: chat.runChat, conversations: conversations.store }),
    { sourceUserId: USER, text: "找外套" },
  );

  assertEquals(conversations.writes.length, 1);
  assertEquals(conversations.writes[0], [
    { role: "user", content: [{ type: "text", text: "找外套" }] },
    {
      role: "assistant",
      content: [{ type: "tool_use", id: "t1", name: "search_products", input: {} }],
    },
    {
      role: "user",
      content: [{ type: "tool_result", tool_use_id: "t1", content: { items: [] } }],
    },
    {
      role: "assistant",
      content: [{ type: "text", text: "為你找到" }, { type: "product", id: PID }],
    },
  ]);
});

Deno.test("a failed turn leaves the conversation untouched", async () => {
  // A stored user message with no answer is a question the next turn's model
  // would read as ignored, so a turn that did not happen is not recorded.
  const conversations = fakeConversations();
  const chat = fakeChat({ throws: new QuotaExceededError(null) });

  await handleTextMessage(
    deps({ runChat: chat.runChat, conversations: conversations.store }),
    { sourceUserId: USER, text: "找外套" },
  );

  assertEquals(conversations.writes, []);
});

Deno.test("a validation failure writes nothing either, stored transcript or not", async () => {
  // No failure kind is special-cased: every one of them leaves the store as it
  // was. A validation error is the one where that is worth stating, because it
  // is the kind most likely to be about the *history* rather than this message
  // — which was already length-checked above — and the transcript it blames is
  // left in place for the idle TTL to retire.
  const prior: ChatMessage[] = [
    { role: "user", content: [{ type: "text", text: "找外套" }] },
  ];
  const conversations = fakeConversations({ prior });
  const chat = fakeChat({ throws: new ValidationError("messages too long") });

  await handleTextMessage(
    deps({ runChat: chat.runChat, conversations: conversations.store }),
    { sourceUserId: USER, text: "有便宜一點的嗎" },
  );

  assertEquals(conversations.writes, []);
});

Deno.test("the answer is pushed before the conversation is written", async () => {
  const trace: string[] = [];
  const { line } = fakeLine();
  const tracingLine: LineApi = {
    ...line,
    push: () => {
      trace.push("push");
      return Promise.resolve();
    },
  };
  const conversations = fakeConversations({ onSave: () => trace.push("save") });
  const chat = fakeChat({ blocks: [{ type: "text", text: "好" }] });

  await handleTextMessage(
    deps({
      line: tracingLine,
      runChat: chat.runChat,
      conversations: conversations.store,
    }),
    { sourceUserId: USER, text: "找外套" },
  );

  // Bookkeeping never delays the reply the user is waiting for.
  assertEquals(trace, ["push", "save"]);
});
