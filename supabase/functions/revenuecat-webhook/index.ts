import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { type DbClient, getAdminClient } from "../_shared/supabase.ts";
import { json } from "../_shared/http.ts";
import { resolveTier } from "./entitlements.ts";
import { fetchSubscriber } from "./revenuecat-api.ts";
import { isAuthorized } from "./authorization.ts";

function requireEnv(name: string): string {
  const value = Deno.env.get(name);
  if (!value) throw new Error(`${name} is not configured`);
  return value;
}

const WEBHOOK_SECRET = requireEnv("REVENUECAT_WEBHOOK_SECRET");
const API_KEY = requireEnv("REVENUECAT_SECRET_API_KEY");

const SUBSCRIPTIONS_TABLE = "subscriptions";

/** Postgres foreign-key violation: the app user id has no row in `auth.users`. */
const FK_VIOLATION = "23503";

const UUID_PATTERN =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

interface RevenueCatEvent {
  type: string;
  id: string;
  app_user_id?: string;
  /** `TRANSFER` only, and the reason `app_user_id` is optional. */
  transferred_from?: string[];
  transferred_to?: string[];
}

/**
 * Which customers to re-read, which is all the event type is used for: state
 * comes from RevenueCat, not from the event's own fields. TRANSFER carries no
 * `app_user_id` and moves entitlements between customers, so both ends need a
 * refresh or the origin keeps a tier it no longer holds.
 */
function affectedAppUserIds(event: RevenueCatEvent): string[] {
  if (event.type === "TRANSFER") {
    return [...(event.transferred_from ?? []), ...(event.transferred_to ?? [])];
  }
  return event.app_user_id ? [event.app_user_id] : [];
}

/** Throws on a transient failure so the caller can answer 5xx and be retried. */
async function syncSubscription(admin: DbClient, appUserId: string): Promise<void> {
  // `Purchases.logIn` sets the app user id to the Supabase auth user id.
  // Anonymous ids ($RCAnonymousID:…) belong to no account and never will.
  if (!UUID_PATTERN.test(appUserId)) {
    console.warn(`Skipping non-account app_user_id: ${appUserId}`);
    return;
  }

  const subscriber = await fetchSubscriber(API_KEY, appUserId);
  const tier = resolveTier(subscriber, new Date());

  const { error } = await admin
    .from(SUBSCRIPTIONS_TABLE)
    .upsert({ user_id: appUserId, tier }, { onConflict: "user_id" });

  if (!error) return;

  if (error.code === FK_VIOLATION) {
    console.warn(`No account for app_user_id ${appUserId}; ignoring event`);
    return;
  }
  throw new Error(`Failed to upsert subscription: ${error.message}`);
}

Deno.serve(async (req) => {
  if (!isAuthorized(req.headers.get("Authorization"), WEBHOOK_SECRET)) {
    console.warn("Unauthorized webhook attempt");
    return json({ error: "Unauthorized" }, 401);
  }

  let event: RevenueCatEvent | undefined;
  try {
    const payload = await req.json() as { event?: RevenueCatEvent };
    event = payload.event;
  } catch {
    return json({ message: "Invalid payload" }, 400);
  }

  if (!event?.type) {
    return json({ message: "Invalid payload" }, 400);
  }

  if (event.type === "TEST") {
    console.log("Received TEST event from RevenueCat");
    return json({ message: "TEST event received" }, 200);
  }

  const appUserIds = affectedAppUserIds(event);
  if (appUserIds.length === 0) {
    console.warn(`No app user id on ${event.type} event ${event.id}`);
    return json({ message: "OK" }, 200);
  }

  try {
    const admin = getAdminClient();
    for (const appUserId of appUserIds) {
      await syncSubscription(admin, appUserId);
    }
    return json({ message: "OK" }, 200);
  } catch (err) {
    // 5xx so RevenueCat retries: a lost event leaves the backend out of step
    // with the store until the next one arrives, which may be a month away.
    console.error(`Failed to handle ${event.type} event ${event.id}:`, err);
    return json({ message: "Sync failed" }, 500);
  }
});
