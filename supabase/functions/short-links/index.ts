import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { type DbClient, getAnonClient } from "../_shared/supabase.ts";
import { publicImageUrl } from "../_shared/storage.ts";
import { json, jsonError } from "../_shared/http.ts";
import {
  channelFromUserAgent,
  codeFromPathname,
  detectSurface,
  platformFromUserAgent,
  type Surface,
} from "./surface.ts";
import { buildStoreDestination, deliveryFor, isOpenWith } from "./destination.ts";

// EdgeRuntime.waitUntil 讓寫入在回應送出之後才跑完。與 line-webhook 同一個寫法，
// 在這裡宣告是為了 Deno 的型別檢查。
declare const EdgeRuntime: { waitUntil(p: Promise<unknown>): void } | undefined;

/**
 * 各開啟方式所需的設定。刻意不在啟動時檢查：缺 LIFF_URL 只該讓 liff 型的連結失敗，
 * 而不是讓整支函式失效 —— 之後 web 型的連結不需要這項設定也要能運作。
 */
const DESTINATION_CONFIG = {
  liffUrl: Deno.env.get("LIFF_URL") ?? null,
};

const IMAGES_BASE_URL = Deno.env.get("R2_PUBLIC_IMAGES_BASE_URL") ?? null;

/**
 * 記錄一次開啟。跑在 `EdgeRuntime.waitUntil` 裡，也就是回應送出之後 —— 所以它自己
 * try/catch：背景任務的 rejection 沒有人會接。
 */
async function recordOpen(
  client: DbClient,
  code: string,
  surface: Surface,
  userAgent: string | null,
): Promise<void> {
  try {
    const { error } = await client.from("link_events").insert({
      code,
      source: surface,
      platform: platformFromUserAgent(userAgent),
      channel: channelFromUserAgent(userAgent),
    });
    if (error) {
      console.error("short-links: failed to record open:", error);
    }
  } catch (err) {
    console.error("short-links: failed to record open:", err);
  }
}

/** 一律 no-store —— 每次呼叫都會記一筆開啟事件，所以呼叫端不能對這支端點加快取。 */
function noStore(response: Response): Response {
  const headers = new Headers(response.headers);
  headers.set("Cache-Control", "no-store");
  return new Response(response.body, { status: response.status, headers });
}

/**
 * 一個短連結 code 指向哪裡：`{ "url": "…" }`。
 *
 * 狀態碼是有意義的：404 是「這個 code 不存在或已停用」，5xx 是「我們壞了」。呼叫端
 * 目前把兩者都導回站台首頁，但區分留在協定裡，因為兩者該給使用者的訊息不同 ——
 * 把故障說成「連結已失效」等於告訴店家的客人他的立牌沒用。
 *
 * `detectSurface` 的結果不影響回應，只寫進 `link_events.source`。之後要不要讓非 LINE
 * 環境改走「點擊進入」而不是 302（iOS 18.3 之後 redirect 不再觸發 universal link），
 * 就靠這份資料決定，而不是靠猜。
 */
Deno.serve(async (req) => {
  try {
    const code = codeFromPathname(new URL(req.url).pathname);
    if (!code) {
      return noStore(jsonError("Malformed code", "NOT_FOUND", 404));
    }

    // anon 就夠了：`short_links` 的 select policy 只放行 is_active 的列，
    // `store_profiles` 本來就公開可讀，`link_events` 有一條匿名 insert policy。
    // 這是一支誰都能呼叫的端點，沒有理由讓它握著 service role key。
    const client = getAnonClient();
    const { data: link, error } = await client
      .from("short_links")
      .select("code, store_id, open_with, store_profiles!inner(name, logo_path)")
      .eq("code", code)
      .eq("is_active", true)
      .maybeSingle();

    if (error) {
      console.error("short-links lookup failed:", error);
      return noStore(jsonError("Lookup failed", "INTERNAL_ERROR", 500));
    }
    if (!link) {
      console.warn(`short-links: unknown or inactive code "${code}"`);
      return noStore(jsonError("Unknown or inactive code", "NOT_FOUND", 404));
    }

    // DB 的 check constraint 只允許已實作的值，所以走到這裡代表 schema 與程式碼不同步。
    if (!isOpenWith(link.open_with)) {
      console.error(`short-links: unsupported open_with "${link.open_with}" on "${link.code}"`);
      return noStore(jsonError("Unsupported link target", "INTERNAL_ERROR", 500));
    }

    const url = buildStoreDestination(link.open_with, link.store_id, DESTINATION_CONFIG);
    if (url === null) {
      console.error(`short-links: missing config for open_with "${link.open_with}"`);
      return noStore(jsonError("Server misconfigured", "INTERNAL_ERROR", 500));
    }

    // 掃碼的人不需要等事件寫完才被導走。實測這次寫入約佔熱路徑回應時間的一半
    // （~0.45s，第二次 PostgREST 往返），而它對使用者沒有任何價值。
    // 型別上 `!inner` 的 to-one 關聯是物件，但視 PostgREST 版本也可能實際回單元素陣列，
    // 所以形狀仍在執行期收斂一次。
    const embedded = link.store_profiles;
    const store = Array.isArray(embedded) ? embedded[0] ?? null : embedded;

    const userAgent = req.headers.get("User-Agent");
    const surface = detectSurface(userAgent);

    const record = recordOpen(client, link.code, surface, userAgent);
    if (typeof EdgeRuntime !== "undefined") EdgeRuntime.waitUntil(record);
    else await record;

    return noStore(json({
      url,
      delivery: deliveryFor(link.open_with, surface),
      store: {
        name: store?.name ?? null,
        logoUrl: store?.logo_path && IMAGES_BASE_URL
          ? publicImageUrl(IMAGES_BASE_URL, store.logo_path)
          : null,
      },
    }));
  } catch (err) {
    console.error("short-links handler error:", err);
    return noStore(jsonError("Internal server error", "INTERNAL_ERROR", 500));
  }
});
