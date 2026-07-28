import { assertEquals } from "jsr:@std/assert";
import {
  dehydrateMessages,
  photoNote,
  redisConversations,
  type RedisLike,
  tryonNote,
} from "./conversation.ts";
import type { ChatMessage } from "../_shared/chat/index.ts";
import type { LineProduct } from "./product-card.ts";

const PID = "8f14e45f-ceea-467a-9c8d-1b2c3d4e5f60";

const someProduct = (over: Partial<LineProduct> = {}): LineProduct => ({
  id: PID,
  name: "短版牛仔外套",
  price: 1280,
  imageUrl: "https://img.example/stores/s1/p1.jpg",
  storeName: "某店",
  purchaseUrl: null,
  ...over,
});

Deno.test("a recommended item is stored as a reference, not as its row", () => {
  const messages: ChatMessage[] = [{
    role: "assistant",
    content: [
      { type: "text", text: "為你找到" },
      { type: "product", item: someProduct() },
      { type: "wardrobe", item: { id: "w1", name: "白襯衫" } },
    ],
  }];

  assertEquals(dehydrateMessages(messages), [{
    role: "assistant",
    content: [
      { type: "text", text: "為你找到" },
      { type: "product", id: PID },
      { type: "wardrobe", id: "w1" },
    ],
  }]);
});

Deno.test("tool rounds are stored verbatim", () => {
  // The model's own record of what it searched and what came back. This is
  // what makes a follow-up like "有便宜一點的嗎" answerable, so none of it may
  // be reshaped on the way into storage.
  const messages: ChatMessage[] = [
    {
      role: "assistant",
      content: [{
        type: "tool_use",
        id: "t1",
        name: "search_products",
        input: { query: "外套" },
      }],
    },
    {
      role: "user",
      content: [{
        type: "tool_result",
        tool_use_id: "t1",
        content: { items: [{ id: PID, name: "短版牛仔外套" }] },
      }],
    },
  ];

  assertEquals(dehydrateMessages(messages), messages);
});

Deno.test("dehydrating what was already stored changes nothing", () => {
  // Every turn re-dehydrates the whole transcript, prior turns included, so
  // this has to be a fixed point or storage would degrade on each pass.
  const stored: ChatMessage[] = [{
    role: "assistant",
    content: [{ type: "text", text: "好" }, { type: "product", id: PID }],
  }];

  assertEquals(dehydrateMessages(stored), stored);
});

Deno.test("an item block naming nothing is dropped", () => {
  const messages: ChatMessage[] = [{
    role: "assistant",
    content: [{ type: "text", text: "好" }, { type: "product", item: {} }],
  }];

  assertEquals(dehydrateMessages(messages), [{
    role: "assistant",
    content: [{ type: "text", text: "好" }],
  }]);
});

Deno.test("a try-on is recorded as a user turn naming the product", () => {
  const note = tryonNote(someProduct());

  assertEquals(note.role, "user");
  assertEquals(note.content, [{
    type: "text",
    text: `（使用者剛試穿了商品 id:${PID}「短版牛仔外套」）`,
  }]);
});

Deno.test("an absurd product name cannot dominate the transcript", () => {
  const note = tryonNote(someProduct({ name: "衣".repeat(60) }));

  assertEquals(
    (note.content[0] as { text: string }).text,
    `（使用者剛試穿了商品 id:${PID}「${"衣".repeat(40)}…」）`,
  );
});

Deno.test("a forwarded photo is recorded as a user turn describing what was sent", () => {
  const note = photoNote("淺藍色寬鬆棉質抽繩長褲");

  assertEquals(note.role, "user");
  assertEquals(note.content, [{
    type: "text",
    text: "（使用者傳了一張衣物照片：淺藍色寬鬆棉質抽繩長褲）",
  }]);
});

interface SetCall {
  key: string;
  value: unknown;
  opts: { ex: number };
}

/** A Redis double recording what was written, with a scripted read or outage. */
function fakeRedis(opts: { stored?: unknown; fails?: boolean } = {}) {
  const gets: string[] = [];
  const sets: SetCall[] = [];
  const down = () => Promise.reject(new Error("upstash down"));
  const client: RedisLike = {
    get: (key) => {
      gets.push(key);
      return opts.fails ? down() : Promise.resolve(opts.stored ?? null);
    },
    set: (key, value, o) => {
      sets.push({ key, value, opts: o });
      return opts.fails ? down() : Promise.resolve("OK");
    },
  };
  return { client, gets, sets };
}

/** Runs `fn` with `console.warn` silenced, returning what it would have logged. */
async function captureWarnings(fn: () => Promise<void>): Promise<unknown[][]> {
  const real = console.warn;
  const calls: unknown[][] = [];
  console.warn = (...args: unknown[]) => {
    calls.push(args);
  };
  try {
    await fn();
  } finally {
    console.warn = real;
  }
  return calls;
}

Deno.test("a conversation is read back under this channel's key", async () => {
  const prior: ChatMessage[] = [
    { role: "user", content: [{ type: "text", text: "找白襯衫" }] },
  ];
  const { client, gets } = fakeRedis({ stored: prior });

  assertEquals(await redisConversations(client).load("Uline123"), prior);
  assertEquals(gets, ["line:conv:Uline123"]);
});

Deno.test("no stored conversation is an empty one, not a failure", async () => {
  const { client } = fakeRedis({ stored: null });

  assertEquals(await redisConversations(client).load("Uline123"), []);
});

Deno.test("a stored value of the wrong shape is discarded", async () => {
  // A value written by an older deploy is not a reason for this one to fail.
  const { client } = fakeRedis({ stored: { messages: [] } });

  assertEquals(await redisConversations(client).load("Uline123"), []);
});

Deno.test("a write carries the idle window as the key's TTL", async () => {
  // The TTL is the whole of the timeout rule: a key that expires is a
  // conversation that ended, and every turn pushes the expiry out again.
  const { client, sets } = fakeRedis();
  const messages: ChatMessage[] = [
    { role: "user", content: [{ type: "text", text: "找白襯衫" }] },
  ];

  await redisConversations(client).save("Uline123", messages);

  assertEquals(sets, [{
    key: "line:conv:Uline123",
    value: messages,
    opts: { ex: 1800 },
  }]);
});

Deno.test("a store that is down costs continuity, not the turn", async () => {
  const store = redisConversations(fakeRedis({ fails: true }).client);

  const warnings = await captureWarnings(async () => {
    assertEquals(await store.load("Uline123"), []);
    await store.save("Uline123", []);
  });

  // Neither call threw, and both left a trace.
  assertEquals(warnings.length, 2);
});
