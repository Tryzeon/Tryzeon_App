import { assertEquals } from "jsr:@std/assert";
import { resolveTier, type Subscriber } from "./entitlements.ts";

const NOW = new Date("2026-08-30T00:00:00Z");
const FUTURE = "2026-09-30T00:00:00Z";
const PAST = "2026-08-29T00:00:00Z";

Deno.test("a lapsed entitlement does not cancel an active one", () => {
  // The bug this replaces: a sandbox subscription expiring while a dashboard
  // grant was active reset the customer to free, because the EXPIRATION event
  // was read as "holds nothing" rather than "this one ended".
  const subscriber: Subscriber = {
    entitlements: {
      pro: { expires_date: PAST },
      max: { expires_date: null },
    },
  };

  assertEquals(resolveTier(subscriber, NOW), "max");
});

Deno.test("the best held entitlement wins", () => {
  const subscriber: Subscriber = {
    entitlements: {
      pro: { expires_date: FUTURE },
      max: { expires_date: FUTURE },
    },
  };

  assertEquals(resolveTier(subscriber, NOW), "max");
});

Deno.test("a grace period still counts as access", () => {
  const subscriber: Subscriber = {
    entitlements: {
      pro: { expires_date: PAST, grace_period_expires_date: FUTURE },
    },
  };

  assertEquals(resolveTier(subscriber, NOW), "pro");
});

Deno.test("every entitlement expired resolves to free", () => {
  const subscriber: Subscriber = {
    entitlements: {
      pro: { expires_date: PAST },
      max: { expires_date: PAST },
    },
  };

  assertEquals(resolveTier(subscriber, NOW), "free");
});

Deno.test("a customer with no entitlements resolves to free", () => {
  assertEquals(resolveTier({}, NOW), "free");
});

Deno.test("an unknown entitlement id is ignored", () => {
  const subscriber: Subscriber = {
    entitlements: { legacy_unlimited: { expires_date: FUTURE } },
  };

  assertEquals(resolveTier(subscriber, NOW), "free");
});

Deno.test("an unparseable expiry is not treated as access", () => {
  const subscriber: Subscriber = {
    entitlements: { max: { expires_date: "not a date" } },
  };

  assertEquals(resolveTier(subscriber, NOW), "free");
});
