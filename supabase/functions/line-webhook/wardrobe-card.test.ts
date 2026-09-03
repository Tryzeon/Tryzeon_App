import { assertEquals, assertRejects } from "jsr:@std/assert";
import {
  fetchWardrobeItemInfo,
  fetchWardrobeRows,
  garmentNoun,
  type LineWardrobeItem,
  tagLine,
  toLineWardrobeItem,
  toWardrobeItemInfo,
  type WardrobeCardRow,
  type WardrobeItemInfo,
  wardrobeInfoContents,
} from "./wardrobe-card.ts";
import { CARD_COLOR } from "./card-kit.ts";
import { WARDROBE_CATEGORY_VALUES } from "../_shared/vocabularies.ts";
import type { Enums } from "../_shared/database.types.ts";

const URL = "https://sig.example/w1.png?token=abc";

const row = (over: Partial<WardrobeCardRow> = {}): WardrobeCardRow => ({
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
  const labels = WARDROBE_CATEGORY_VALUES.map(
    (c) => toLineWardrobeItem(row({ category: c }), URL)?.categoryLabel,
  );
  assertEquals(labels, ["上衣", "下身", "外套", "套裝", "其他"]);
});

Deno.test("an unknown category shows its own code rather than dropping the card", () => {
  // The cast stands in for a deployed function reading a schema newer than the
  // types it was built against.
  const grown = "hats" as Enums<"wardrobe_category">;
  assertEquals(toLineWardrobeItem(row({ category: grown }), URL)?.categoryLabel, "hats");
});

Deno.test("toLineWardrobeItem drops an item whose image could not be signed", () => {
  assertEquals(toLineWardrobeItem(row(), undefined), null);
});

Deno.test("toLineWardrobeItem keeps at most three tags and ignores blank ones", () => {
  const got = toLineWardrobeItem(
    row({ tags: ["a", "", "b", "c", "d"] }),
    URL,
  );
  assertEquals(got?.tags, ["a", "b", "c"]);
});

Deno.test("a NULL tag drops that tag rather than the whole hydration", () => {
  // `tags` is `text[]` with no element constraint: the generated `string[]`
  // cannot say an element may be NULL, and a row written through PostgREST can
  // carry one. Reading it as a string would take every card in the carousel.
  const got = toLineWardrobeItem(
    row({ tags: ["a", null, "b"] as unknown as string[] }),
    URL,
  );
  assertEquals(got?.tags, ["a", "b"]);
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

Deno.test("garmentNoun keeps a real noun as-is", () => {
  assertEquals(garmentNoun("上衣"), "上衣");
  assertEquals(garmentNoun("下身"), "下身");
  assertEquals(garmentNoun("外套"), "外套");
  assertEquals(garmentNoun("套裝"), "套裝");
});

Deno.test("garmentNoun turns the others bucket, and anything unmapped, into 單品", () => {
  assertEquals(garmentNoun("其他"), "單品");
  assertEquals(garmentNoun("hats"), "單品");
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

Deno.test("fetchWardrobeRows binds the query to the asking user", async () => {
  const { admin, eqCalls, inCalls } = fakeAdmin(
    [row()],
    signedOk(["u1/top/w1.png"]),
  );
  await fetchWardrobeRows(admin, "u1", ["w1"]);

  // Not a filter — this path runs on the admin client with no RLS beneath it,
  // so without the eq an id from one sender reads another's wardrobe.
  assertEquals(eqCalls, [["user_id", "u1"]]);
  assertEquals(inCalls, [["w1"]]);
});

Deno.test("fetchWardrobeRows signs the whole set in one call", async () => {
  const paths = ["u1/top/w1.png", "u1/top/w2.png"];
  const { admin, signCalls } = fakeAdmin(
    [row(), row({ id: "w2", image_path: paths[1] })],
    signedOk(paths),
  );
  const rows = await fetchWardrobeRows(admin, "u1", ["w1", "w2"]);

  assertEquals(signCalls.length, 1);
  assertEquals(signCalls[0], paths);
  assertEquals([...rows.keys()], ["w1", "w2"]);
});

Deno.test("an item whose url came back null is absent, so its block drops", async () => {
  const { admin } = fakeAdmin([row(), row({ id: "w2", image_path: "u1/top/w2.png" })], {
    data: [
      { error: null, path: "u1/top/w1.png", signedUrl: "https://sig.example/w1?t=1" },
      { error: "not found", path: "u1/top/w2.png", signedUrl: null },
    ],
    error: null,
  });
  const rows = await fetchWardrobeRows(admin, "u1", ["w1", "w2"]);

  assertEquals([...rows.keys()], ["w1"]);
});

Deno.test("fetchWardrobeRows queries and signs nothing for an empty id list", async () => {
  const { admin, inCalls, signCalls } = fakeAdmin([], { data: [], error: null });
  const rows = await fetchWardrobeRows(admin, "u1", []);

  assertEquals(inCalls, []);
  assertEquals(signCalls, []);
  assertEquals(rows.size, 0);
});

Deno.test("fetchWardrobeRows throws when signing fails outright", async () => {
  const { admin } = fakeAdmin([row()], { data: null, error: { message: "boom" } });
  await assertRejects(() => fetchWardrobeRows(admin, "u1", ["w1"]), Error, "boom");
});

function fakeItemAdmin(row: Record<string, unknown> | null) {
  const filters: Array<[string, string]> = [];
  let signCalls = 0;
  const client = {
    from() {
      return {
        select() {
          const chain = {
            eq(column: string, value: string) {
              filters.push([column, value]);
              return chain;
            },
            maybeSingle: () => Promise.resolve({ data: row, error: null }),
          };
          return chain;
        },
      };
    },
    storage: {
      from() {
        return {
          createSignedUrls() {
            signCalls++;
            return Promise.resolve({ data: [], error: null });
          },
        };
      },
    },
  };
  // deno-lint-ignore no-explicit-any
  return { admin: client as any, filters, signCalls: () => signCalls };
}

Deno.test("fetchWardrobeItemInfo binds the read to the asking user", async () => {
  const { admin, filters } = fakeItemAdmin(row());
  await fetchWardrobeItemInfo(admin, "u1", "w1");

  assertEquals(filters, [["id", "w1"], ["user_id", "u1"]]);
});

Deno.test("fetchWardrobeItemInfo signs nothing", async () => {
  const { admin, signCalls } = fakeItemAdmin(row());
  await fetchWardrobeItemInfo(admin, "u1", "w1");

  assertEquals(signCalls(), 0);
});

Deno.test("fetchWardrobeItemInfo yields the text fields and no image url", async () => {
  const { admin } = fakeItemAdmin(row());
  const info = await fetchWardrobeItemInfo(admin, "u1", "w1");

  assertEquals(info, { id: "w1", categoryLabel: "上衣", tags: ["寬鬆", "米色"] });
});

Deno.test("fetchWardrobeItemInfo is null for an item that is gone or never theirs", async () => {
  // One answer for both: telling them apart would be an existence oracle.
  const { admin } = fakeItemAdmin(null);
  assertEquals(await fetchWardrobeItemInfo(admin, "u1", "w1"), null);
});

Deno.test("toWardrobeItemInfo needs no url to describe an item", () => {
  assertEquals(toWardrobeItemInfo(row()), {
    id: "w1",
    categoryLabel: "上衣",
    tags: ["寬鬆", "米色"],
  });
});
