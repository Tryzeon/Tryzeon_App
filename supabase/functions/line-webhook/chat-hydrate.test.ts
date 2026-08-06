import { assertEquals } from "jsr:@std/assert";
import { makeLineAnswerRows } from "./chat-hydrate.ts";
import type { AnswerRef } from "../_shared/chat/index.ts";

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

/** Fake client recording the ids `.in()` was called with. */
function fakeAdmin(rows: Record<string, unknown>[]) {
  const queried: string[][] = [];
  const client = {
    from() {
      return {
        select() {
          return {
            in(_column: string, ids: string[]) {
              queried.push(ids);
              return Promise.resolve({ data: rows, error: null });
            },
          };
        },
      };
    },
  };
  // deno-lint-ignore no-explicit-any
  return { admin: client as any, queried };
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

// Which rows survive the read — an image-less product, an id whose row is
// gone, an empty id list — is `fetchProductCards`' rule and is tested there.
// What is left here is the hydrator's own share: which refs become a query,
// where the base url goes, and that wardrobe always comes back as a map.

Deno.test("the base url reaches the card", async () => {
  const { admin } = fakeAdmin([row()]);
  const rows = await makeLineAnswerRows(`${BASE}/`)(admin, "u1", [
    { type: "product", id: "p1" },
  ]);

  assertEquals(rows.products.get("p1")?.imageUrl, "https://img.example/stores/s1/p1.jpg");
});

Deno.test("a wardrobe ref never becomes a product query, and wardrobe is always empty", async () => {
  const { admin, queried } = fakeAdmin([row()]);
  const rows = await makeLineAnswerRows(BASE)(admin, "u1", [
    { type: "text", text: "再多說一點" },
    { type: "wardrobe", id: "w1" },
  ]);

  assertEquals(queried, []);
  assertEquals(rows.products.size, 0);
  assertEquals(rows.wardrobe.size, 0);
});
