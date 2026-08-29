import { assertEquals, assertRejects } from "jsr:@std/assert";
import { buildWardrobeGarmentDetail, resolveWardrobeGarment } from "./wardrobe.ts";
import { LIMITS } from "./types.ts";
import { ValidationError } from "./errors.ts";
import type { DbClient } from "../supabase.ts";

const ID = "44444444-4444-4444-4444-444444444444";

interface LookupStub {
  row: Record<string, unknown> | null;
  error?: { message: string };
}

/**
 * Fake client recording every `.eq()` the resolver applied, so a test can prove
 * the ownership bound reached the query rather than merely trusting the code.
 */
function fakeAdmin(stub: LookupStub) {
  const filters: Array<[string, string]> = [];
  const admin = {
    from: (_table: string) => ({
      select: () => {
        const chain = {
          eq: (column: string, value: string) => {
            filters.push([column, value]);
            return chain;
          },
          maybeSingle: () => {
            // Behave like the database: the row comes back only when every
            // filter the resolver applied actually matches it. Recording the
            // filters is not enough — without this, deleting the ownership
            // bound would leave the SECURITY test below still passing.
            const row = stub.row;
            const match = row !== null &&
              filters.every(([column, value]) => row[column] === value);
            return Promise.resolve({
              data: match ? row : null,
              error: stub.error ?? null,
            });
          },
        };
        return chain;
      },
    }),
  } as unknown as DbClient;
  return { admin, filters };
}

Deno.test("buildWardrobeGarmentDetail joins category and tags", () => {
  assertEquals(
    buildWardrobeGarmentDetail({
      image_path: "u1/top/a.png",
      category: "top",
      tags: ["寬鬆", "米色"],
    }),
    "Category: top. Tags: 寬鬆, 米色",
  );
});

Deno.test("buildWardrobeGarmentDetail passes the enum code through untranslated", () => {
  // The only enum→Chinese map belongs to the LINE card, which dresses rows for
  // people. A second copy here would be one more thing to keep in step.
  assertEquals(
    buildWardrobeGarmentDetail({ image_path: "p", category: "others", tags: [] }),
    "Category: others",
  );
});

Deno.test("buildWardrobeGarmentDetail omits the tags part rather than leaving it blank", () => {
  // The category always has one: the column is a NOT NULL enum, so only the
  // tags half can be absent.
  assertEquals(
    buildWardrobeGarmentDetail({ image_path: "p", category: "bottoms", tags: null }),
    "Category: bottoms",
  );
  assertEquals(
    buildWardrobeGarmentDetail({ image_path: "p", category: "bottoms", tags: [] }),
    "Category: bottoms",
  );
});

Deno.test("buildWardrobeGarmentDetail ignores blank and non-string tags", () => {
  // `tags` is `text[]` with no element constraint, so a row can hold a NULL the
  // generated `string[]` says is impossible. Dropping the element beats a
  // `.trim()` on null turning one bad tag into a 500.
  assertEquals(
    buildWardrobeGarmentDetail({
      image_path: "p",
      category: "top",
      tags: ["a", 7, "", null, "  ", "b"] as unknown as string[],
    }),
    "Category: top. Tags: a, b",
  );
});

Deno.test("buildWardrobeGarmentDetail caps overlong detail at the limit", () => {
  const detail = buildWardrobeGarmentDetail({
    image_path: "p",
    category: "top",
    tags: ["x".repeat(LIMITS.MAX_GARMENT_DETAIL_LENGTH + 200)],
  });
  assertEquals(detail.length, LIMITS.MAX_GARMENT_DETAIL_LENGTH);
});

Deno.test("resolveWardrobeGarment rejects an id that cannot name a row", async () => {
  // A uuid check here, not at the query: Postgres answers a malformed uuid with
  // a 22P02 that would surface as a server fault rather than a bad request.
  const { admin } = fakeAdmin({ row: null });
  await assertRejects(
    () => resolveWardrobeGarment(admin, "u1", "not-a-uuid"),
    ValidationError,
    "invalid wardrobeItemId",
  );
});

Deno.test("resolveWardrobeGarment binds the read to the asking user", async () => {
  const { admin, filters } = fakeAdmin({
    row: { id: ID, user_id: "u1", image_path: "u1/top/a.png", category: "top", tags: ["寬鬆"] },
  });
  await resolveWardrobeGarment(admin, "u1", ID);

  // Both filters, in the query, every time. This is the whole reason the
  // function exists rather than each adapter reading the table itself.
  assertEquals(filters, [["id", ID], ["user_id", "u1"]]);
});

Deno.test("resolveWardrobeGarment yields one image source and the detail", async () => {
  const { admin } = fakeAdmin({
    row: { id: ID, user_id: "u1", image_path: "u1/top/a.png", category: "top", tags: ["寬鬆"] },
  });
  const garment = await resolveWardrobeGarment(admin, "u1", ID);

  // Single, not a group: `wardrobe_items.image_path` is one column, unlike a
  // product's `image_paths` array of angles.
  assertEquals(garment, {
    images: [{ path: "u1/top/a.png" }],
    detail: "Category: top. Tags: 寬鬆",
  });
});

Deno.test("resolveWardrobeGarment still describes a row with no tags", async () => {
  const { admin } = fakeAdmin({
    row: { id: ID, user_id: "u1", image_path: "u1/top/a.png", category: "top", tags: [] },
  });
  const garment = await resolveWardrobeGarment(admin, "u1", ID);

  assertEquals(garment, {
    images: [{ path: "u1/top/a.png" }],
    detail: "Category: top",
  });
});

Deno.test("SECURITY: another user's item is indistinguishable from one that does not exist", async () => {
  // Both cases are the `.eq("user_id")` returning nothing. If the two ever
  // report differently, this function becomes an oracle for probing whether an
  // id sits in somebody else's wardrobe. Do not "improve" either message.
  const missing = await assertRejects(
    () => resolveWardrobeGarment(fakeAdmin({ row: null }).admin, "u1", ID),
    ValidationError,
  );
  const someoneElses = await assertRejects(
    () =>
      resolveWardrobeGarment(
        fakeAdmin({
          row: { id: ID, user_id: "u1", image_path: "u1/top/a.png", category: "top", tags: [] },
        }).admin,
        "u2",
        ID,
      ),
    ValidationError,
  );

  assertEquals(missing.message, `no wardrobe item for wardrobeItemId: ${ID}`);
  assertEquals(missing.message, someoneElses.message);
});

Deno.test("resolveWardrobeGarment treats a blank image_path as no item", async () => {
  const { admin } = fakeAdmin({ row: { id: ID, user_id: "u1", image_path: "   ", category: "top", tags: [] } });
  await assertRejects(
    () => resolveWardrobeGarment(admin, "u1", ID),
    ValidationError,
    "no wardrobe item",
  );
});

Deno.test("resolveWardrobeGarment rejects a row whose path points outside its owner's folder", async () => {
  // The row itself passes the `user_id` filter, but `image_path` is
  // client-written free text and here names another user's folder — the same
  // rejection as a missing row, so it carries nothing to probe with.
  const { admin } = fakeAdmin({
    row: { id: ID, user_id: "u1", image_path: "u2/top/a.png", category: "top", tags: [] },
  });
  await assertRejects(
    () => resolveWardrobeGarment(admin, "u1", ID),
    ValidationError,
    `no wardrobe item for wardrobeItemId: ${ID}`,
  );
});

Deno.test("resolveWardrobeGarment raises a broken query as a fault, not a bad request", async () => {
  // A missing row is something a caller can be told about; a broken query is
  // ours to fix, so it must not arrive as a ValidationError.
  const { admin } = fakeAdmin({ row: null, error: { message: "boom" } });
  const err = await assertRejects(() => resolveWardrobeGarment(admin, "u1", ID), Error);
  assertEquals(err instanceof ValidationError, false);
  assertEquals(err.message.includes("boom"), true);
});
