import { assertEquals, assertThrows } from "@std/assert";
import { parseServiceAccount } from "./config.ts";

const KEY_FILE = JSON.stringify({
  type: "service_account",
  project_id: "tryzeon-497616",
  private_key_id: "abc123",
  private_key: "-----BEGIN PRIVATE KEY-----\nMIIE\n-----END PRIVATE KEY-----\n",
  client_email: "vertex@tryzeon-497616.iam.gserviceaccount.com",
  client_id: "12345",
  token_uri: "https://oauth2.googleapis.com/token",
});

Deno.test("parseServiceAccount reads a key file pasted as JSON", () => {
  assertEquals(parseServiceAccount(KEY_FILE), {
    projectId: "tryzeon-497616",
    clientEmail: "vertex@tryzeon-497616.iam.gserviceaccount.com",
    privateKey: "-----BEGIN PRIVATE KEY-----\nMIIE\n-----END PRIVATE KEY-----\n",
    privateKeyId: "abc123",
  });
});

Deno.test("parseServiceAccount tolerates surrounding whitespace", () => {
  assertEquals(parseServiceAccount(`\n  ${KEY_FILE}\n`), parseServiceAccount(KEY_FILE));
});

Deno.test("parseServiceAccount leaves the private key's newlines real", () => {
  const { privateKey } = parseServiceAccount(KEY_FILE);
  assertEquals(privateKey.includes("\\n"), false);
  assertEquals(privateKey.split("\n").length, 4);
});

Deno.test("parseServiceAccount keeps privateKeyId optional", () => {
  const withoutId = JSON.stringify({
    project_id: "p",
    client_email: "e",
    private_key: "k",
  });
  assertEquals(parseServiceAccount(withoutId).privateKeyId, undefined);
});

Deno.test("parseServiceAccount names every missing field at once", () => {
  const error = assertThrows(
    () => parseServiceAccount(JSON.stringify({ project_id: "p" })),
    Error,
  );
  assertEquals(
    error.message,
    "GOOGLE_SERVICE_ACCOUNT is missing: client_email, private_key",
  );
});

Deno.test("parseServiceAccount rejects anything that is not JSON", () => {
  for (const raw of ["not json at all", "{ oops", ""]) {
    assertThrows(() => parseServiceAccount(raw), Error, "is not valid JSON");
  }
});
