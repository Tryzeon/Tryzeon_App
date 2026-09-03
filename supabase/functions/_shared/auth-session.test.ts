import { assertEquals, assertRejects } from "jsr:@std/assert";
import { mintSessionForUser } from "./auth-session.ts";
import type { DbClient } from "./supabase.ts";

interface AdminStub {
  email?: string | null;
  getUserError?: string;
  hashedToken?: string | null;
  generateLinkError?: string;
  seen: { email?: string };
}

function fakeAdmin(stub: AdminStub): DbClient {
  return {
    auth: {
      admin: {
        getUserById: (_id: string) =>
          Promise.resolve({
            data: stub.getUserError ? null : { user: { email: stub.email } },
            error: stub.getUserError ? { message: stub.getUserError } : null,
          }),
        generateLink: (params: { type: string; email: string }) => {
          stub.seen.email = params.email;
          return Promise.resolve({
            data: stub.generateLinkError
              ? null
              : { properties: { hashed_token: stub.hashedToken } },
            error: stub.generateLinkError ? { message: stub.generateLinkError } : null,
          });
        },
      },
    },
  } as unknown as DbClient;
}

function fakeAnon(
  session: { refresh_token: string } | null,
  error?: string,
): DbClient {
  return {
    auth: {
      verifyOtp: (_p: unknown) =>
        Promise.resolve({
          data: session ? { session } : { session: null },
          error: error ? { message: error } : null,
        }),
    },
  } as unknown as DbClient;
}

Deno.test("mintSessionForUser returns the refresh token of the minted session", async () => {
  const admin = fakeAdmin({ email: "line_U1@liff.tryzeon.app", hashedToken: "hash", seen: {} });
  const result = await mintSessionForUser(admin, "user-1", fakeAnon({ refresh_token: "rt" }));
  assertEquals(result, { refreshToken: "rt" });
});

Deno.test("mintSessionForUser generates the link for the user's own email", async () => {
  // The invariant that keeps this endpoint from being an account factory: the
  // email is read back from the user id, never supplied by a caller.
  const stub: AdminStub = { email: "line_U9@liff.tryzeon.app", hashedToken: "hash", seen: {} };
  await mintSessionForUser(fakeAdmin(stub), "user-9", fakeAnon({ refresh_token: "rt" }));
  assertEquals(stub.seen.email, "line_U9@liff.tryzeon.app");
});

Deno.test("mintSessionForUser rejects when the user lookup fails", async () => {
  const admin = fakeAdmin({ getUserError: "boom", seen: {} });
  await assertRejects(
    () => mintSessionForUser(admin, "user-1", fakeAnon({ refresh_token: "rt" })),
    Error,
    "user lookup failed",
  );
});

Deno.test("mintSessionForUser rejects when the user has no email", async () => {
  const admin = fakeAdmin({ email: null, seen: {} });
  await assertRejects(
    () => mintSessionForUser(admin, "user-1", fakeAnon({ refresh_token: "rt" })),
    Error,
    "user lookup failed",
  );
});

Deno.test("mintSessionForUser rejects when generateLink returns no hashed token", async () => {
  const admin = fakeAdmin({ email: "a@b.c", hashedToken: null, seen: {} });
  await assertRejects(
    () => mintSessionForUser(admin, "user-1", fakeAnon({ refresh_token: "rt" })),
    Error,
    "generateLink failed",
  );
});

Deno.test("mintSessionForUser rejects when the OTP verification yields no session", async () => {
  const admin = fakeAdmin({ email: "a@b.c", hashedToken: "hash", seen: {} });
  await assertRejects(
    () => mintSessionForUser(admin, "user-1", fakeAnon(null, "expired")),
    Error,
    "verifyOtp failed",
  );
});
