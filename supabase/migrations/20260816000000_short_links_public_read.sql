-- 讓 short-links edge function 改用 anon key。
--
-- 這支端點完全公開：掃 QR 進來，沒有任何 session。它只做兩件事 —— 查一筆有效的
-- short_links、記一筆開啟事件 —— 兩件都不需要繞過 RLS。原本握著 service role key，
-- 等於讓一支誰都能呼叫的端點持有整個資料庫的權限。

-- 讀：只開放 is_active 的列。停用的連結對匿名者直接不存在，與端點回 404 同一個語意。
create policy "Anyone can resolve an active short link"
  on public.short_links for select
  using (is_active);

-- 寫：誰都能新增一筆開啟事件，但不能宣稱事件屬於某個使用者。
--
-- 「匿名者能不能偽造事件」不是這條 policy 擋得住的 —— 端點本身就公開，打一輪迴圈
-- 有同樣效果。真正要守住的只有 user_id：那是唯一無法從 User-Agent 推出來、且會污染
-- 歸因的欄位。source / platform / channel 本來就是從可竄改的 User-Agent 猜出來的
-- best-effort 值，限制它們不會多擋住任何事。
--
-- 目前沒有任何路徑會寫入帶 user_id 的事件（record_link_open 已在 20260811000000
-- 移除），所以這條限制不會擋掉現有的任何寫入。
create policy "Anyone can record a link open"
  on public.link_events for insert
  with check (user_id is null);

-- link_events 刻意不給 select policy：寫得進去，讀不出來。edge function 的 insert
-- 走 return=minimal，不需要讀回，開啟次數則由後台以 service role 統計。
