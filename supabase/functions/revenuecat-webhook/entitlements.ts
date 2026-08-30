/**
 * Tier resolution from a RevenueCat subscriber, kept free of I/O so the rules
 * that decide what a customer is entitled to can be tested directly.
 */

/** One entry of `subscriber.entitlements` in `GET /v1/subscribers/{id}`. */
export interface SubscriberEntitlement {
  expires_date?: string | null;
  grace_period_expires_date?: string | null;
  product_identifier?: string;
  purchase_date?: string;
}

export interface Subscriber {
  entitlements?: Record<string, SubscriberEntitlement> | null;
}

/**
 * Entitlement ids in RevenueCat, which are also the `subscription_tiers.id`
 * values — the two are deliberately the same string so no mapping table is
 * needed. Mirrors `AppConstants.entitlement*Id` on the client.
 */
export const SUBSCRIPTION_TIER = {
  free: "free",
  pro: "pro",
  max: "max",
} as const;

export type SubscriptionTier = typeof SUBSCRIPTION_TIER[keyof typeof SUBSCRIPTION_TIER];

/** Best first. A customer holding both entitlements gets the better one. */
const TIER_PRECEDENCE: readonly SubscriptionTier[] = [
  SUBSCRIPTION_TIER.max,
  SUBSCRIPTION_TIER.pro,
];

/**
 * A missing `expires_date` is an entitlement that never ends — a lifetime
 * purchase or a dashboard grant. A billing-retry grace period is still access,
 * so it extends the deadline rather than being a state of its own.
 */
function isActive(entitlement: SubscriberEntitlement, now: Date): boolean {
  const expires = entitlement.expires_date;
  if (!expires) return true;

  const grace = entitlement.grace_period_expires_date;
  const deadline = grace ? Math.max(Date.parse(expires), Date.parse(grace)) : Date.parse(expires);

  return Number.isFinite(deadline) && deadline > now.getTime();
}

/**
 * The customer's whole entitlement set decides the tier, never a single event.
 * RevenueCat does not guarantee webhook ordering, and one entitlement expiring
 * says nothing about the others — a sandbox subscription lapsing while a
 * dashboard grant is active must not drop the customer to free.
 */
export function resolveTier(subscriber: Subscriber, now: Date): SubscriptionTier {
  const entitlements = subscriber.entitlements ?? {};

  for (const tier of TIER_PRECEDENCE) {
    const entitlement = entitlements[tier];
    if (entitlement && isActive(entitlement, now)) return tier;
  }

  return SUBSCRIPTION_TIER.free;
}
