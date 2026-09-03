import { assertEquals } from "@std/assert";
import { buildStoreDestination, deliveryFor, isOpenWith } from "./destination.ts";

const LIFF = { liffUrl: "https://liff.line.me/1234-abcd" };

Deno.test("buildStoreDestination builds the LIFF store path", () => {
  assertEquals(
    buildStoreDestination("liff", "d01f159f", LIFF),
    "https://liff.line.me/1234-abcd/store/d01f159f",
  );
});

Deno.test("buildStoreDestination tolerates a trailing slash on the LIFF base url", () => {
  assertEquals(
    buildStoreDestination("liff", "d01f159f", { liffUrl: "https://liff.line.me/1234-abcd/" }),
    "https://liff.line.me/1234-abcd/store/d01f159f",
  );
});

Deno.test("buildStoreDestination reports missing config instead of a broken url", () => {
  assertEquals(buildStoreDestination("liff", "d01f159f", { liffUrl: null }), null);
});

Deno.test("isOpenWith accepts only implemented opening methods", () => {
  // The DB check constraint likewise only allows implemented values; both sides
  // are the same list.
  assertEquals(isOpenWith("liff"), true);
  assertEquals(isOpenWith("web"), false);
  assertEquals(isOpenWith("app"), false);
  assertEquals(isOpenWith(null), false);
});

Deno.test("deliveryFor lets only LINE's in-app browser take a redirect", () => {
  assertEquals(deliveryFor("liff", "line"), "redirect");
  assertEquals(deliveryFor("liff", "web"), "interstitial");
});

Deno.test("deliveryFor gives a crawler a page, never a redirect", () => {
  assertEquals(deliveryFor("liff", "bot"), "interstitial");
});
