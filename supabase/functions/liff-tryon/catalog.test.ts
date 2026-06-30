import { assertEquals, assertRejects } from "jsr:@std/assert";
import { resolveProductGarmentKey } from "./catalog.ts";
import { ValidationError } from "./request.ts";

const UUID_A = "11111111-1111-1111-1111-111111111111";
const UUID_B = "22222222-2222-2222-2222-222222222222";
const UUID_C = "33333333-3333-3333-3333-333333333333";

function fakeAdmin(row: unknown) {
  // deno-lint-ignore no-explicit-any
  const admin: any = {
    from() {
      return {
        select() {
          return {
            eq() {
              return {
                maybeSingle() {
                  return Promise.resolve({ data: row, error: null });
                },
              };
            },
          };
        },
      };
    },
  };
  return admin;
}

Deno.test("resolveProductGarmentKey returns the first stores/ key", async () => {
  const admin = fakeAdmin({ image_paths: ["stores/s/p/a.jpg", "stores/s/p/b.jpg"] });
  assertEquals(await resolveProductGarmentKey(admin, UUID_A), "stores/s/p/a.jpg");
});

Deno.test("resolveProductGarmentKey throws when product not found", async () => {
  const admin = fakeAdmin(null);
  await assertRejects(() => resolveProductGarmentKey(admin, UUID_B), ValidationError);
});

Deno.test("resolveProductGarmentKey throws when no stores/ image", async () => {
  const admin = fakeAdmin({ image_paths: ["product-images/legacy.jpg"] });
  await assertRejects(() => resolveProductGarmentKey(admin, UUID_C), ValidationError);
});

Deno.test("resolveProductGarmentKey rejects a non-UUID productId without querying the DB", async () => {
  // deno-lint-ignore no-explicit-any
  const exploding: any = {
    from() {
      throw new Error("DB must not be queried for an invalid productId");
    },
  };
  await assertRejects(() => resolveProductGarmentKey(exploding, "not-a-uuid"), ValidationError);
});
