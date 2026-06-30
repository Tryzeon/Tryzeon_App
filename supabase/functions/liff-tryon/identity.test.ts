import { assertEquals } from "jsr:@std/assert";
import { resolveSupabaseUser } from "./identity.ts";

// Minimal chainable fake of the bits of SupabaseClient that identity.ts uses.
function makeFakeAdmin(opts: {
  existingUserId?: string | null;
  createdUserId?: string;
}) {
  const calls = { createUserCalled: false, insertedRow: null as unknown };
  // deno-lint-ignore no-explicit-any
  const admin: any = {
    from(_table: string) {
      return {
        select() {
          return {
            eq() {
              return {
                maybeSingle() {
                  return Promise.resolve({
                    data: opts.existingUserId
                      ? { user_id: opts.existingUserId }
                      : null,
                    error: null,
                  });
                },
              };
            },
          };
        },
        insert(row: unknown) {
          calls.insertedRow = row;
          return Promise.resolve({ error: null });
        },
      };
    },
    auth: {
      admin: {
        createUser(_args: unknown) {
          calls.createUserCalled = true;
          return Promise.resolve({
            data: { user: { id: opts.createdUserId } },
            error: null,
          });
        },
      },
    },
  };
  return { admin, calls };
}

Deno.test("returns existing user_id on a returning visit (no createUser)", async () => {
  const { admin, calls } = makeFakeAdmin({ existingUserId: "uuid-existing" });
  const id = await resolveSupabaseUser(admin, { sub: "U1" });
  assertEquals(id, "uuid-existing");
  assertEquals(calls.createUserCalled, false);
});

Deno.test("creates user + inserts link on first visit", async () => {
  const { admin, calls } = makeFakeAdmin({
    existingUserId: null,
    createdUserId: "uuid-new",
  });
  const id = await resolveSupabaseUser(admin, { sub: "U2", name: "Eric" });
  assertEquals(id, "uuid-new");
  assertEquals(calls.createUserCalled, true);
  assertEquals(calls.insertedRow, { line_user_id: "U2", user_id: "uuid-new" });
});
