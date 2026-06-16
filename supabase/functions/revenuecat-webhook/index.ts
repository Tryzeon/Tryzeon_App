import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { getAdminClient } from "../_shared/supabase.ts";

// ── Configuration ──────────────────────────────────────────────────────────

const WEBHOOK_SECRET = Deno.env.get("REVENUECAT_WEBHOOK_SECRET");

if (!WEBHOOK_SECRET) {
  throw new Error("REVENUECAT_WEBHOOK_SECRET is not configured");
}

// ── Types ──────────────────────────────────────────────────────────────────

interface RevenueCatEvent {
  type: string;
  id: string;
  app_user_id: string;
  original_app_user_id: string;
  aliases: string[];
  product_id?: string;
  entitlement_ids?: string[] | null;
  purchased_at_ms?: number;
  expiration_at_ms?: number | null;
  environment: string;
  store?: string;
}

interface WebhookPayload {
  api_version: string;
  event: RevenueCatEvent;
}

// Events where we resolve the new plan from entitlement_ids
const PLAN_CHANGE_EVENTS = new Set([
  "INITIAL_PURCHASE",
  "RENEWAL",
  "UNCANCELLATION",
  "SUBSCRIPTION_EXTENDED",
  "PRODUCT_CHANGE",
  "NON_RENEWING_PURCHASE",
]);

// Events where the user loses access → reset to free
const RESET_TO_FREE_EVENTS = new Set([
  "EXPIRATION",
]);

// Events where we keep the current plan (CANCELLATION, BILLING_ISSUE, SUBSCRIPTION_PAUSED)
// These are handled in the else branch — the user still has access until expiration.

// ── Helpers ────────────────────────────────────────────────────────────────

/**
 * Maps RevenueCat entitlement_ids to the plan id in subscription_plans table.
 * Priority: max > pro > free
 */
function resolveEntitlementToPlanId(entitlementIds?: string[] | null): string {
  if (!entitlementIds || entitlementIds.length === 0) return "free";
  if (entitlementIds.includes("max")) return "max";
  if (entitlementIds.includes("pro")) return "pro";
  return "free";
}

// ── Main Handler ───────────────────────────────────────────────────────────

Deno.serve(async (req) => {
  try {
    // 1. Verify Authorization header
    const authHeader = req.headers.get("Authorization");
    const expectedHeader = `Bearer ${WEBHOOK_SECRET}`;

    if (!authHeader || authHeader !== expectedHeader) {
      console.warn("Unauthorized webhook attempt");
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        { status: 401, headers: { "Content-Type": "application/json" } }
      );
    }

    // 2. Parse event payload
    const payload: WebhookPayload = await req.json();
    const event = payload.event;

    if (!event || !event.type) {
      return new Response(
        JSON.stringify({ message: "Invalid payload" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    // 3. Handle TEST event — just acknowledge
    if (event.type === "TEST") {
      console.log("Received TEST event from RevenueCat");
      return new Response(
        JSON.stringify({ message: "TEST event received" }),
        { status: 200, headers: { "Content-Type": "application/json" } }
      );
    }

    // 4. Resolve user_id from app_user_id
    //    RevenueCat app_user_id is set via Purchases.logIn(userId) which uses the Supabase auth user id.
    const userId = event.app_user_id;
    if (!userId) {
      console.warn("Missing app_user_id in webhook event");
      return new Response(
        JSON.stringify({ message: "Missing app_user_id" }),
        { status: 200, headers: { "Content-Type": "application/json" } }
      );
    }

    // 5. Determine plan based on event type
    const eventType = event.type;
    const adminClient = getAdminClient();
    let planId: string;

    if (PLAN_CHANGE_EVENTS.has(eventType)) {
      // Active subscription events → resolve plan from entitlement_ids
      planId = resolveEntitlementToPlanId(event.entitlement_ids);
    } else if (RESET_TO_FREE_EVENTS.has(eventType)) {
      // Expired → reset to free
      planId = "free";
    } else {
      // CANCELLATION, BILLING_ISSUE, SUBSCRIPTION_PAUSED
      // Plan doesn't change — user still has access until expiration.
      return new Response(
        JSON.stringify({ message: "OK" }),
        { status: 200, headers: { "Content-Type": "application/json" } }
      );
    }

    // 6. Upsert subscriptions table
    const { error: upsertError } = await adminClient
      .from("subscriptions")
      .upsert(
        {
          user_id: userId,
          plan: planId,
        },
        { onConflict: "user_id" }
      );

    if (upsertError) {
      console.error("Failed to upsert subscription:", upsertError);
      // Still return 200 to prevent RevenueCat retries for DB errors we can investigate
      return new Response(
        JSON.stringify({ message: "Upsert failed", error: upsertError.message }),
        { status: 200, headers: { "Content-Type": "application/json" } }
      );
    }

    return new Response(
      JSON.stringify({ message: "OK" }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );
  } catch (err) {
    console.error("Webhook handler error:", err);

    // Always return 200 to prevent infinite retries from RevenueCat.
    // Errors are logged for investigation.
    return new Response(
      JSON.stringify({ message: "Internal error (logged)" }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );
  }
});
