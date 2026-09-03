import { assertEquals } from "jsr:@std/assert@^1.0.19";
import { makeLineAnswerRows } from "./chat-hydrate.ts";
import type { AnswerRef } from "../_shared/chat/index.ts";
import type { LineProduct } from "./product-card.ts";

const BASE = "https://img.example";

const row = (over: Record<string, unknown> = {}) => ({
  id: "p1",
  name: "白襯衫",
  price: 1200,
  image_paths: ["stores/s1/p1.jpg"],
  purchase_link: null,
  store_profiles: { name: "某店" },
  ...over,
});

function fakeAdmin(
  productRows: Record<string, unknown>[],
  wardrobeRows: Record<string, unknown>[] = [],
) {
  const tables: string[] = [];
  const queried: string[][] = [];
  const eqCalls: Array<[string, string]> = [];

  const client = {
    from(table: string) {
      const rows = table === "products" ? productRows : wardrobeRows;
      // Recorded on an actual `.in()` run, not on `.from()` alone: both
      // hydrators build their query unconditionally, so only the run itself
      // tells a real read apart from a query built and never fired.
      const runIn = (ids: string[]) => {
        tables.push(table);
        queried.push(ids);
        return Promise.resolve({ data: rows, error: null });
      };
      return {
        select() {
          return {
            in: (_c: string, ids: string[]) => runIn(ids),
            eq(column: string, value: string) {
              eqCalls.push([column, value]);
              return { in: (_c: string, ids: string[]) => runIn(ids) };
            },
          };
        },
      };
    },
    storage: {
      from() {
        return {
          createSignedUrls(paths: string[], _expiresIn: number) {
            return Promise.resolve({
              data: paths.map((p) => ({
                error: null,
                path: p,
                signedUrl: `https://sig.example/${p}?t=1`,
              })),
              error: null,
            });
          },
        };
      },
    },
  };

  // deno-lint-ignore no-explicit-any
  return { admin: client as any, tables, queried, eqCalls };
}

Deno.test("hydrates only the referenced product ids", async () => {
  const { admin, queried } = fakeAdmin([row(), row({ id: "p2", name: "黑褲" })]);
  const hydrate = makeLineAnswerRows(BASE);
  const refs: AnswerRef[] = [
    { type: "text", text: "為你找到" },
    { type: "product", id: "p1" },
    { type: "product", id: "p2" },
  ];

  const rows = await hydrate(admin, "u1", refs);

  assertEquals(queried, [["p1", "p2"]]);
  assertEquals([...rows.products.keys()], ["p1", "p2"]);
});

// Which rows survive the read is `fetchProductRows`' rule and is tested there.

Deno.test("the base url reaches the card", async () => {
  const { admin } = fakeAdmin([row()]);
  const rows = await makeLineAnswerRows(`${BASE}/`)(admin, "u1", [
    { type: "product", id: "p1" },
  ]);

  assertEquals(
    (rows.products.get("p1") as LineProduct).imageUrl,
    "https://img.example/stores/s1/p1.jpg",
  );
});

Deno.test("a wardrobe ref reads the wardrobe, bound to the asking user", async () => {
  const wardrobeRow = {
    id: "w1",
    image_path: "u1/top/w1.png",
    category: "top",
    tags: ["寬鬆"],
  };
  const { admin, tables, eqCalls } = fakeAdmin([], [wardrobeRow]);

  const rows = await makeLineAnswerRows(BASE)(admin, "u1", [
    { type: "wardrobe", id: "w1" },
  ]);

  assertEquals(tables, ["wardrobe_items"]);
  assertEquals(eqCalls, [["user_id", "u1"]]);
  assertEquals([...rows.wardrobe.keys()], ["w1"]);
});

Deno.test("neither kind of ref queries the other's table", async () => {
  const { admin, tables } = fakeAdmin([row()], []);

  await makeLineAnswerRows(BASE)(admin, "u1", [
    { type: "text", text: "再多說一點" },
    { type: "product", id: "p1" },
  ]);

  assertEquals(tables, ["products"]);
});
