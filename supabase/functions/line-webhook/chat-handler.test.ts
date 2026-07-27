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
import type { LineApi } from "./line-api.ts";

const USER = "Uline123";

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
function fakeChat(outcome: { blocks: ContentBlock[] } | { throws: unknown }) {
  const seen: { params: ChatParams; deps: RunChatAgentDeps }[] = [];
  const runChat: typeof runChatAgent = (_clients, params, deps = {}) => {
    seen.push({ params, deps });
    if ("throws" in outcome) return Promise.reject(outcome.throws);
    return Promise.resolve({ blocks: outcome.blocks, messages: [], usage: null });
  };
  return { runChat, seen };
}

function deps(over: Partial<ChatHandlerDeps> = {}): ChatHandlerDeps {
  return {
    // deno-lint-ignore no-explicit-any
    admin: {} as any,
    line: fakeLine().line,
    imagesBaseUrl: "https://img.example",
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
  // The transcript is exactly this message: nothing is stored between turns.
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
