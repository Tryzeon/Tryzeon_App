import type { Subscriber } from "./entitlements.ts";

const SUBSCRIBERS_ENDPOINT = "https://api.revenuecat.com/v1/subscribers";

export class RevenueCatApiError extends Error {
  constructor(readonly status: number, message: string) {
    super(message);
    this.name = "RevenueCatApiError";
  }
}

/**
 * The customer's current state, which is the only thing the webhook trusts.
 * The response merges sandbox and production receipts under one customer, so a
 * TestFlight tester and a paying user resolve through the same path.
 */
export async function fetchSubscriber(
  apiKey: string,
  appUserId: string,
): Promise<Subscriber> {
  const response = await fetch(
    `${SUBSCRIBERS_ENDPOINT}/${encodeURIComponent(appUserId)}`,
    { headers: { Authorization: `Bearer ${apiKey}`, Accept: "application/json" } },
  );

  if (!response.ok) {
    throw new RevenueCatApiError(
      response.status,
      `RevenueCat subscriber fetch failed (${response.status}): ${await response.text()}`,
    );
  }

  const body = await response.json() as { subscriber?: Subscriber };
  return body.subscriber ?? {};
}
