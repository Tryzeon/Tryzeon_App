export type Surface = "bot" | "line" | "web";

/** The same rule as the migration's short_links_code_format check. */
const CODE_PATTERN = /^[a-z0-9][a-z0-9-]{1,31}$/;

/** The prefix is deliberately not checked: the function need not know which
 * public path it is mounted under. */
export function codeFromPathname(pathname: string): string | null {
  const segments = pathname.split("/").filter(Boolean);
  if (segments.length === 0) return null;
  const code = segments[segments.length - 1].toLowerCase();
  return CODE_PATTERN.test(code) ? code : null;
}

/** Crawlers are matched first: preview prefetches masquerade as ordinary browser
 * traffic, and counting them as scans dilutes the performance metrics. */
const BOT_PATTERN = /bot\b|crawler|spider|preview|facebookexternalhit|embedly|quora link/i;

export function detectSurface(userAgent: string | null): Surface {
  if (!userAgent) return "web";
  if (BOT_PATTERN.test(userAgent)) return "bot";
  if (/\bLine\//i.test(userAgent)) return "line";
  return "web";
}

export function platformFromUserAgent(userAgent: string | null): string {
  if (!userAgent) return "other";
  if (/android/i.test(userAgent)) return "android";
  if (/iphone|ipad|ipod/i.test(userAgent)) return "ios";
  return "other";
}

/**
 * Order matters: match the most specific token first — Instagram and Messenger
 * each have their own marker but also carry Facebook's FBAN/FBAV along with
 * it.
 */
export function channelFromUserAgent(userAgent: string | null): string | null {
  if (!userAgent) return null;
  if (/Instagram/i.test(userAgent)) return "instagram";
  if (/\bLine\//i.test(userAgent)) return "line";
  if (/Messenger|Orca-Android/i.test(userAgent)) return "messenger";
  if (/Barcelona/i.test(userAgent)) return "threads"; // Threads codename
  if (/FBAN|FBAV|FB_IAB/i.test(userAgent)) return "facebook";
  return null;
}
