-- short_links 從 polymorphic (target_type, target_id) 改為 typed FK store_id。
--
-- 為什麼:polymorphic 組合在 Postgres 無法下 foreign key,所以 target_id 可以指向
-- 一個不存在的店家而無人察覺 —— 印出去的 QR 就是死的。typed FK 讓 DB 保證目標
-- 存在。日後要支援商品連結時走 exclusive arc:store_id 改 nullable、加 product_id、
-- 加 check (num_nonnulls(store_id, product_id) = 1)。
--
-- 同時:
--   * 刪 forward_url —— 舊的 deferred deep link 平台已移除,且自由文字 URL 是
--     open redirect 來源
--   * metadata jsonb 改成 note text —— 原本存的 name/store 都可從 code 與
--     store_profiles 推導,不可推導的只有「印在哪」這行備註
--   * code 加小寫格式 check —— 原本 PK 大小寫敏感,PinkyRabbit 與 pinkyrabbit
--     會是兩筆
--   * link_events.code 的 FK 補 on delete cascade —— 否則刪店家會被 FK 擋住並變成
--     HTTP 500,與 20260619000000 修過的 link_events.user_id 同一類問題
--
-- short_links 目前無資料(link_events.code 對它有 FK,所以事件表同樣是空的),
-- 因此直接重建而不逐欄位搬遷。

alter table public.link_events drop constraint if exists link_events_code_fkey;

drop table if exists public.short_links;

create table public.short_links (
  code       text primary key,
  store_id   uuid not null references public.store_profiles(id) on delete cascade,
  is_active  boolean not null default true,
  note       text,
  created_at timestamptz not null default now(),
  constraint short_links_code_format check (code ~ '^[a-z0-9][a-z0-9-]{1,31}$')
);

alter table public.short_links enable row level security;
-- 只有 service_role(resolve-link edge function)存取這張表。不設 policy =>
-- anon/authenticated 預設拒絕。

alter table public.link_events
  add constraint link_events_code_fkey
  foreign key (code) references public.short_links(code)
  on update cascade on delete cascade;

-- record_link_open 是給 App 內解析 /s/{code} 用的,而 QR 現在落在 LIFF、App 端的
-- 解析器已經刪除,所以這支 RPC 沒有任何呼叫端了。
--
-- 已安裝的舊版 App binary 仍會攔截 /s/ 並呼叫它,呼叫會失敗 —— 那條路徑上的
-- resolveShortLinkDestination 會接住錯誤並退回首頁。這是刻意接受的降級:為尚未
-- 更新的版本留一支沒人維護的 RPC,就是 backward-compat 包袱。新 QR 印 /q/,不受影響。
drop function if exists public.record_link_open(text, text, text);
