import { assertEquals } from "jsr:@std/assert";
import { buildStoreDestination, isOpenWith } from "./destination.ts";

const LIFF = { liffUrl: "https://liff.line.me/1234-abcd" };

Deno.test("buildStoreDestination builds the LIFF store path", () => {
  assertEquals(
    buildStoreDestination("liff", "d01f159f", LIFF),
    "https://liff.line.me/1234-abcd/store/d01f159f",
  );
});

Deno.test("buildStoreDestination tolerates a trailing slash on the LIFF base url", () => {
  // liffUrl 是人工設定的環境變數,結尾多一條斜線會產生 //store/ 這種路徑。
  assertEquals(
    buildStoreDestination("liff", "d01f159f", { liffUrl: "https://liff.line.me/1234-abcd/" }),
    "https://liff.line.me/1234-abcd/store/d01f159f",
  );
});

Deno.test("buildStoreDestination reports missing config instead of a broken url", () => {
  // 缺 LIFF_URL 只能讓 liff 型的連結失敗,不該讓整支函式失效 —— 之後 web 型的連結
  // 不需要這項設定也要能運作。
  assertEquals(buildStoreDestination("liff", "d01f159f", { liffUrl: null }), null);
});

Deno.test("isOpenWith accepts only implemented opening methods", () => {
  // DB 的 check constraint 也只允許已實作的值,兩邊是同一份清單。
  assertEquals(isOpenWith("liff"), true);
  assertEquals(isOpenWith("web"), false);
  assertEquals(isOpenWith("app"), false);
  assertEquals(isOpenWith(null), false);
});
