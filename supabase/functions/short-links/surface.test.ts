import { assertEquals } from "jsr:@std/assert";
import {
  channelFromUserAgent,
  codeFromPathname,
  detectSurface,
  platformFromUserAgent,
} from "./surface.ts";

const LINE_UA =
  "Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 Line/14.9.0";
const SAFARI_UA =
  "Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 Version/17.5 Safari/604.1";

Deno.test("codeFromPathname takes the last segment and lowercases it", () => {
  // 端點掛在哪不影響解析，所以函式不需要知道自己的部署路徑。
  assertEquals(codeFromPathname("/functions/v1/short-links/PinkyRabbit"), "pinkyrabbit");
  assertEquals(codeFromPathname("/short-links/pinkyrabbit"), "pinkyrabbit");
  assertEquals(codeFromPathname("/short-links/pinkyrabbit/"), "pinkyrabbit");
});

Deno.test("codeFromPathname rejects anything the code format forbids", () => {
  // 格式與 short_links_code_format check 一致，所以壞碼在查表前就被擋掉。
  assertEquals(codeFromPathname("/short-links/bad_code"), null);
  assertEquals(codeFromPathname("/short-links/a"), null);
  assertEquals(codeFromPathname("/short-links/-lead"), null);
  assertEquals(codeFromPathname("/"), null);
  assertEquals(codeFromPathname(""), null);
});

Deno.test("detectSurface puts LINE's in-app browser on the LIFF path", () => {
  assertEquals(detectSurface(LINE_UA), "line");
});

Deno.test("detectSurface treats an external browser as web", () => {
  assertEquals(detectSurface(SAFARI_UA), "web");
  // 沒有 UA 時不猜：落地頁對所有人都可用，302 進 LIFF 只對 LINE 內有效。
  assertEquals(detectSurface(null), "web");
});

Deno.test("detectSurface identifies preview crawlers before anything else", () => {
  // 社群 App 送出連結時會預抓做預覽卡，這些不是人，不能算進掃碼數。
  assertEquals(detectSurface("facebookexternalhit/1.1"), "bot");
  assertEquals(detectSurface("Twitterbot/1.0"), "bot");
  assertEquals(detectSurface("Slackbot-LinkExpanding 1.0"), "bot");
  assertEquals(detectSurface("Mozilla/5.0 (compatible; Googlebot/2.1)"), "bot");
});

Deno.test("platformFromUserAgent reports os for analytics", () => {
  assertEquals(platformFromUserAgent(LINE_UA), "ios");
  assertEquals(platformFromUserAgent("Mozilla/5.0 (Linux; Android 14)"), "android");
  assertEquals(platformFromUserAgent("Mozilla/5.0 (Macintosh)"), "other");
  assertEquals(platformFromUserAgent(null), "other");
});

Deno.test("channelFromUserAgent never guesses an undetectable channel", () => {
  assertEquals(channelFromUserAgent(LINE_UA), "line");
  assertEquals(channelFromUserAgent("Instagram 300.0"), "instagram");
  assertEquals(channelFromUserAgent(SAFARI_UA), null);
  assertEquals(channelFromUserAgent(null), null);
});
