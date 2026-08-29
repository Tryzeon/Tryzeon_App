import { assertEquals } from "jsr:@std/assert";
import { getOrCreateUserId } from "./line-user.ts";
import type { DbClient } from "./supabase.ts";

interface AdminStub {
  /** Set to simulate a LINE account already linked to an auth user. */
  existingUserId?: string;
  /** `user_metadata` of every `createUser` call, in order. */
  created: (Record<string, unknown> | undefined)[];
}

function fakeAdmin(stub: AdminStub): DbClient {
  return {
    from: (_table: string) => ({
      select: () => ({
        eq: () => ({
          maybeSingle: () =>
            Promise.resolve({
              data: stub.existingUserId ? { user_id: stub.existingUserId } : null,
              error: null,
            }),
        }),
      }),
      insert: () => Promise.resolve({ error: null }),
    }),
    auth: {
      admin: {
        createUser: (params: Record<string, unknown>) => {
          stub.created.push(params.user_metadata as Record<string, unknown>);
          return Promise.resolve({ data: { user: { id: "minted-user" } }, error: null });
        },
      },
    },
  } as unknown as DbClient;
}

Deno.test("getOrCreateUserId does not look a name up when the link already exists", async () => {
  // The webhook passes a resolver on every message. Spending a LINE API call to
  // learn a name already recorded is the cost this guards against.
  const stub: AdminStub = { existingUserId: "known-user", created: [] };
  let calls = 0;
  const userId = await getOrCreateUserId(fakeAdmin(stub), { sub: "U1" }, () => {
    calls++;
    return Promise.resolve("小明");
  });

  assertEquals(userId, "known-user");
  assertEquals(calls, 0);
  assertEquals(stub.created.length, 0);
});

Deno.test("getOrCreateUserId does not look a name up when the caller already has one", async () => {
  const stub: AdminStub = { created: [] };
  let calls = 0;
  await getOrCreateUserId(fakeAdmin(stub), { sub: "U1", name: "小明" }, () => {
    calls++;
    return Promise.resolve("別的名字");
  });

  assertEquals(calls, 0);
  assertEquals(stub.created, [{ name: "小明" }]);
});

Deno.test("getOrCreateUserId mints with the looked-up display name", async () => {
  const stub: AdminStub = { created: [] };
  const userId = await getOrCreateUserId(
    fakeAdmin(stub),
    { sub: "U1" },
    () => Promise.resolve("小明"),
  );

  assertEquals(userId, "minted-user");
  assertEquals(stub.created, [{ name: "小明" }]);
});

Deno.test("getOrCreateUserId still mints when the name lookup fails", async () => {
  // A missing display name is cosmetic; failing to mint the user would drop the
  // message the caller is mid-way through answering.
  const stub: AdminStub = { created: [] };
  const userId = await getOrCreateUserId(
    fakeAdmin(stub),
    { sub: "U1" },
    () => Promise.reject(new Error("LINE profile failed 404")),
  );

  assertEquals(userId, "minted-user");
  assertEquals(stub.created, [{}]);
});

Deno.test("getOrCreateUserId mints without a name when no resolver is given", async () => {
  const stub: AdminStub = { created: [] };
  await getOrCreateUserId(fakeAdmin(stub), { sub: "U1" });

  assertEquals(stub.created, [{}]);
});
