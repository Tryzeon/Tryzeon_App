import { assertEquals, assertRejects } from "jsr:@std/assert";
import {
  fetchWardrobeCards,
  type LineWardrobeItem,
  tagLine,
  toLineWardrobeItem,
  wardrobeInfoContents,
} from "./wardrobe-card.ts";
import { CARD_COLOR } from "./card-kit.ts";

const URL = "https://sig.example/w1.png?token=abc";

const row = (over: Record<string, unknown> = {}) => ({
  id: "w1",
  image_path: "u1/top/w1.png",
  category: "top",
  tags: ["寬鬆", "米色"],
  ...over,
});

const item = (over: Partial<LineWardrobeItem> = {}): LineWardrobeItem => ({
  id: "w1",
  imageUrl: URL,
  categoryLabel: "上衣",
  tags: ["寬鬆", "米色"],
  ...over,
});

Deno.test("toLineWardrobeItem maps the row onto the card's fields", () => {
  assertEquals(toLineWardrobeItem(row(), URL), {
    id: "w1",
    imageUrl: URL,
    categoryLabel: "上衣",
    tags: ["寬鬆", "米色"],
  });
});

Deno.test("every wardrobe_category code has a label", () => {
  const labels = ["top", "bottoms", "outerwear", "sets", "others"].map(
    (c) => toLineWardrobeItem(row({ category: c }), URL)?.categoryLabel,
  );
  assertEquals(labels, ["上衣", "下身", "外套", "套裝", "其他"]);
});

Deno.test("an unknown category shows its own code rather than dropping the card", () => {
  // The column is an enum, so an unknown code means the enum grew and this map
  // did not — easier to spot on a card than as a silently missing item.
  assertEquals(toLineWardrobeItem(row({ category: "hats" }), URL)?.categoryLabel, "hats");
});

Deno.test("toLineWardrobeItem drops an item whose image could not be signed", () => {
  assertEquals(toLineWardrobeItem(row(), undefined), null);
});

Deno.test("toLineWardrobeItem keeps at most three tags and ignores non-strings", () => {
  const got = toLineWardrobeItem(
    row({ tags: ["a", 7, "b", null, "c", "d"] }),
    URL,
  );
  assertEquals(got?.tags, ["a", "b", "c"]);
});

Deno.test("toLineWardrobeItem tolerates a row with no tags", () => {
  assertEquals(toLineWardrobeItem(row({ tags: null }), URL)?.tags, []);
});

Deno.test("tagLine hashes each tag onto one line", () => {
  assertEquals(tagLine(["寬鬆", "米色"]), "#寬鬆 #米色");
  assertEquals(tagLine([]), "");
});

Deno.test("tagLine truncates a line LINE would reject the whole send for", () => {
  const long = tagLine(["a".repeat(50)]);
  assertEquals(long.length, 41);
  assertEquals(long.endsWith("…"), true);
});

Deno.test("the info block is category, tags and the wardrobe label", () => {
  // deno-lint-ignore no-explicit-any
  const contents = wardrobeInfoContents(item()) as any[];

  assertEquals(contents.length, 3);
  assertEquals(contents[0].text, "上衣");
  assertEquals(contents[0].color, CARD_COLOR.primary);
  assertEquals(contents[1].text, "#寬鬆 #米色");
  assertEquals(contents[1].color, CARD_COLOR.muted);
  assertEquals(contents[2].text, "你的衣櫃");
  assertEquals(contents[2].color, CARD_COLOR.muted);
});

Deno.test("an item with no tags shows two lines, not an empty middle one", () => {
  // deno-lint-ignore no-explicit-any
  const contents = wardrobeInfoContents(item({ tags: [] })) as any[];

  assertEquals(contents.length, 2);
  assertEquals(contents[0].text, "上衣");
  assertEquals(contents[1].text, "你的衣櫃");
});

/**
 * Fake client answering one `.eq().in()` row lookup and one batch signing call.
 * Records both so a test can assert the user bound the query and that signing
 * happened once for the whole set.
 */
function fakeAdmin(
  rows: Record<string, unknown>[],
  // deno-lint-ignore no-explicit-any
  signed: { data: any; error: any },
) {
  const eqCalls: Array<[string, string]> = [];
  const inCalls: string[][] = [];
  const signCalls: string[][] = [];

  const client = {
    from() {
      return {
        select() {
          return {
            eq(column: string, value: string) {
              eqCalls.push([column, value]);
              return {
                in(_column: string, ids: string[]) {
                  inCalls.push(ids);
                  return Promise.resolve({ data: rows, error: null });
                },
              };
            },
          };
        },
      };
    },
    storage: {
      from() {
        return {
          createSignedUrls(paths: string[], _expiresIn: number) {
            signCalls.push(paths);
            return Promise.resolve(signed);
          },
        };
      },
    },
  };

  // deno-lint-ignore no-explicit-any
  return { admin: client as any, eqCalls, inCalls, signCalls };
}

const signedOk = (paths: string[]) => ({
  data: paths.map((p) => ({ error: null, path: p, signedUrl: `https://sig.example/${p}?t=1` })),
  error: null,
});

Deno.test("fetchWardrobeCards binds the query to the asking user", async () => {
  const { admin, eqCalls, inCalls } = fakeAdmin(
    [row()],
    signedOk(["u1/top/w1.png"]),
  );
  await fetchWardrobeCards(admin, "u1", ["w1"]);

  // Not a filter — this path runs on the admin client with no RLS beneath it,
  // so without the eq an id from one sender reads another's wardrobe.
  assertEquals(eqCalls, [["user_id", "u1"]]);
  assertEquals(inCalls, [["w1"]]);
});

Deno.test("fetchWardrobeCards signs the whole set in one call", async () => {
  const paths = ["u1/top/w1.png", "u1/top/w2.png"];
  const { admin, signCalls } = fakeAdmin(
    [row(), row({ id: "w2", image_path: paths[1] })],
    signedOk(paths),
  );
  const cards = await fetchWardrobeCards(admin, "u1", ["w1", "w2"]);

  assertEquals(signCalls.length, 1);
  assertEquals(signCalls[0], paths);
  assertEquals([...cards.keys()], ["w1", "w2"]);
});

Deno.test("an item whose url came back null is absent, so its block drops", async () => {
  const { admin } = fakeAdmin([row(), row({ id: "w2", image_path: "u1/top/w2.png" })], {
    data: [
      { error: null, path: "u1/top/w1.png", signedUrl: "https://sig.example/w1?t=1" },
      { error: "not found", path: "u1/top/w2.png", signedUrl: null },
    ],
    error: null,
  });
  const cards = await fetchWardrobeCards(admin, "u1", ["w1", "w2"]);

  assertEquals([...cards.keys()], ["w1"]);
});

Deno.test("fetchWardrobeCards queries and signs nothing for an empty id list", async () => {
  const { admin, inCalls, signCalls } = fakeAdmin([], { data: [], error: null });
  const cards = await fetchWardrobeCards(admin, "u1", []);

  assertEquals(inCalls, []);
  assertEquals(signCalls, []);
  assertEquals(cards.size, 0);
});

Deno.test("fetchWardrobeCards throws when signing fails outright", async () => {
  // Same rule the product path follows: a broken read is a server fault, and
  // reporting it as "I found nothing" would charge the caller for a lie.
  const { admin } = fakeAdmin([row()], { data: null, error: { message: "boom" } });
  await assertRejects(() => fetchWardrobeCards(admin, "u1", ["w1"]), Error, "boom");
});
