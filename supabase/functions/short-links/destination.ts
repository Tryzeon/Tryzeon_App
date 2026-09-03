import type { Surface } from "./surface.ts";

/**
 * The open methods that are implemented. When adding `web` / `app`, widen the
 * migration's `short_links_open_with_check` to match.
 */
const OPEN_WITH = ["liff"] as const;

export type OpenWith = typeof OPEN_WITH[number];

export function isOpenWith(value: unknown): value is OpenWith {
  return typeof value === "string" && (OPEN_WITH as readonly string[]).includes(value);
}

export interface DestinationConfig {
  liffUrl: string | null;
}

/** Returns null when the config this open method needs is missing — callers turn
 * that into a 500. */
export function buildStoreDestination(
  openWith: OpenWith,
  storeId: string,
  config: DestinationConfig,
): string | null {
  switch (openWith) {
    case "liff":
      return config.liffUrl === null
        ? null
        : `${config.liffUrl.replace(/\/+$/, "")}/store/${storeId}`;
    default: {
      const unhandled: never = openWith;
      throw new Error(`unhandled open_with: ${unhandled}`);
    }
  }
}

/**
 * Why not always 302: a liff destination is a LIFF URL, and a LIFF URL is an iOS
 * universal link. Apple's DTS states outright that a 301/302 to a universal link
 * no longer opens the app as of iOS 18.3
 * (developer.apple.com/forums/thread/780496), and LINE itself does not guarantee
 * an external browser can launch a LIFF, recommending a user tap instead
 * (developers.line.biz/en/tips/2026/05/07/line-launch-issue/).
 *
 * So please do not turn the interstitial into an automatic redirect — that path
 * is broken on iOS.
 */
export type Delivery = "redirect" | "interstitial";

export function deliveryFor(openWith: OpenWith, surface: Surface): Delivery {
  switch (openWith) {
    case "liff":
      // Crawlers get the interstitial too — the preview card needs the OG tags.
      return surface === "line" ? "redirect" : "interstitial";
    default: {
      const unhandled: never = openWith;
      throw new Error(`unhandled open_with: ${unhandled}`);
    }
  }
}
