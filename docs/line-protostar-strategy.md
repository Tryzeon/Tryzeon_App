# Tryzeon × LINE 整合策略與 LINE 新星計劃（PROTOSTAR）申請報告

> 內部策略文件 — 給創辦人。
> 資料截止：2026 年 6 月。所有標註「需查證」「信心：中／低」的項目，請勿在對外簡報當成既定事實引用，押資源前先經官方管道確認。
> 幣別一律為新台幣（NT$ / TWD）。
>
> 本報告整併四份研究：① LINE 新星計劃（PROTOSTAR）申請提案 ② 玩美移動（Perfect Corp）LINE 整合競品分析 ③ LINE 服飾電商現況查證 ④ LINE 整合方案盤點與發展路線評審。

---

## 目錄

1. [執行摘要（先讀這個）](#1-執行摘要先讀這個)
2. [LINE 新星計劃（PROTOSTAR）是什麼](#2-line-新星計劃protostar是什麼)
3. [報名資格與重點注意事項](#3-報名資格與重點注意事項)
4. [市場現況：LINE 上的衣服「賣得到、卻試不到」](#4-市場現況line-上的衣服賣得到卻試不到)
5. [競品分析：玩美移動（Perfect Corp）在 LINE 的整合](#5-競品分析玩美移動perfect-corp在-line-的整合)
6. [可用的 LINE SDK / API 與整合方案全景](#6-可用的-line-sdk--api-與整合方案全景)
7. [Tryzeon × LINE 整合藍圖（技術架構）](#7-tryzeon--line-整合藍圖技術架構)
8. [⭐ 總體推薦發展路線（序貫組合三階段）](#8--總體推薦發展路線序貫組合三階段)
9. [分階段落地計畫（Roadmap）](#9-分階段落地計畫roadmap)
10. [提案 Pitch 重點與 KPI](#10-提案-pitch-重點與-kpi)
11. [成本與限制](#11-成本與限制)
12. [下一步行動清單（Checklist）](#12-下一步行動清單checklist)
13. [需查證清單（彙整）](#13-需查證清單彙整)
14. [附錄：關鍵官方查證連結](#14-附錄關鍵官方查證連結)

---

## 1. 執行摘要（先讀這個）

**Tryzeon**（生成式 AI 服飾虛擬試穿 + 智慧衣櫥；Flutter App + Supabase 後端；核心 UX 為「上傳照片 → 伺服器端生成」）**該不該申請 LINE 新星計劃？該。** 同時落在 PROTOSTAR 歷史五大焦點的 **AI** 與 **O2O 零售** 兩塊，門檻低（公司成立 5 年內 / A 輪前 / 未上市），核心福利（免費 LINE 官方帳號一年、約 NT$30 萬行銷資源、Deloitte/中華開發加速器輔導、投資媒合）正對早期消費性產品的痛點。

**最強單一切入角度：**
> **「把生成式 AI『全身/全套穿搭』試穿帶進 LINE 生態系——填補 LINE 現有空白。」**
> LINE 在台已驗證的試穿全是**美妝 AR 疊圖**（玩美移動 Perfect Corp 提供）；**服飾全身的生成式（diffusion）試穿在 LINE 平台是真實的類別空白（whitespace）**。服飾品牌已大量在 LINE 賣衣服，但「試穿」這塊沒人做。

**三個關鍵結論：**

1. **整合終局核心 = 認證版 LINE MINI App，但用「速度路線」開場。** 不必在 LIFF / MINI App / 聊天機器人之間二選一——它們是不同分工的層。先用 LINE Login + 免審核 LIFF 幾週內量出試穿漏斗，再把同一個 web app 升級成認證 MINI App。**讓數據而非審核排程決定何時送認證。**

2. **Tryzeon 的「上傳照片 → 伺服器生成」模式天然適配 LIFF webview**（不需即時相機 `getUserMedia`）。玩美的即時 AR 反而被相機限制綁住、只能用站內瀏覽器網頁——這是 Tryzeon 能做出更深 LINE-native 體驗的結構性優勢。

3. **玩美是「市場驗證者」而非要正面打的對手。** 它已把「虛擬試穿 = 提升轉換、有預算科目」教育給 LINE 的品牌生態，但它在 LINE 的產品**只有美妝、不含服飾**。Tryzeon 是補位，不是賭新類別。但窗口非永久（玩美 2025/5 已推生成式服飾、2026/1 再加 9 類 Fashion API），**要搶速度先鎖定 LINE 服飾品牌**。

**最重要的 3 件事（先做）：**
1. 先用 **LINE Login + LIFF** 做一個能跑的試穿 MVP（幾乎零成本、免審核），累積真實數據再申請。
2. 寄信 `dl_protostar@linecorp.com` / 看 `protostar.line.me`，**查證 2026 報名狀態與條款**（截止日、必繳文件、廣告金現值皆未公開）。
3. 第一天就做好「上傳人像照片」的 **PDPA 合規與內容安全護欄**——這對試穿產品是法遵 + 平台下架的雙重關鍵。

---

## 2. LINE 新星計劃（PROTOSTAR）是什麼

| 項目 | 內容 | 信心 |
|---|---|---|
| **正式名稱** | LINE PROTOSTAR 新星計劃（「計劃／計畫」同義異寫，皆指 Protostar） | 高 |
| **營運方** | **LINE Taiwan**（台灣，非日本 LINE）。2018 升級後與 **中華開發創新加速器（CDIB）** 及 **勤業眾信 Deloitte** 合作 | 高 |
| **地區** | 台灣市場為主（東南亞拓展可接 LINE Thailand 的 SCALEUP） | 高 |
| **宗旨** | 讓行動/數位新創在 LINE 平台上開發並擴張服務，提供生態系資源、輔導與投資媒合；兼具 LINE 企業創投（CVC）漏斗角色 | 高 |
| **歷史焦點領域** | O2O、娛樂內容、IoT、FinTech、**AI** | 高 |
| **現況（2025–2026）** | **仍在營運**。2015/12 啟動、2018 升級；官網帶 10 週年素材、持續開放申請入口 | 高（持續中）／梯次細節：中 |

**核心福利（以官方 about 頁與 2020 報導為準）：**
- 免費 **LINE 官方帳號**，第一年免付 LINE 平台費用
- 約 **NT$30 萬** 的 LINE 行銷/廣告資源
- 技術諮詢、chatbot/API 開發資源、商業模式輔導
- Deloitte（財務、股權、盡職調查）＋ CDIB 加速器課程與一對一顧問
- 國內外資源媒合、networking
- 表現優異者可成為 **LINE 直接投資的優先標的**（如 TaxiGo → LINE TAXI）

**累積成效（約 2020 數據）：** 5+ 年、平台資源投入破 NT$1 億、接觸 300+ 新創、40+ 服務在 LINE 上線、平均 6–9 個月可上線。

> **易混淆，勿搞錯目標：** 「新星計劃」= PROTOSTAR 新創孵化。它**不是** LINE Creators Market（貼圖）、不是 LINE 官方帳號商用方案、不是中小店家數位轉型應援、不是 Biz-Solutions 認證合作夥伴。

---

## 3. 報名資格與重點注意事項

### 報名資格（官方 about 三條件）
1. **公司成立 5 年以內**
2. **尚未接受 A 輪投資**（A 輪前）
3. **尚未公開上市**（私人持有）

> 無公開營收門檻；不需事先擁有 OA（會免費提供）。

### 申請方式與篩選標準
- 透過 `protostar.line.me`「加入新星計劃」頁，及/或 email `dl_protostar@linecorp.com`。
- LINE 引述的篩選標準：**執行力、可持續成長動能、在 LINE 平台擴張的潛力、創新性、團隊實力**。
- LINE 常問的三問：**你要在 LINE 上做什麼？與 LINE 合作後的突破是什麼？為什麼是你？**（並看重創辦人品格與在地化）

### 義務（第一年後三選一）
| 選項 | 內容 |
|---|---|
| ① 特別折扣費率 | 沿用第一年合約義務，付折扣後服務費 |
| ② 退出計劃 | 改付一般 OA 標準價 |
| ③ 以公司股權換取續年免費 OA | 額外免費一年，LINE 保留最終核准權（比例/估值未揭露） |

### 風險與務必注意

**(A) 個資 / PDPA — 上傳人像照片是最高風險點（對試穿產品特別關鍵）**
- 人像/身體照片屬**敏感個資**，《個資法》要求**有效同意、告知目的、最小蒐集、限期保存、安全維護**。
- 「用 LINE OA 做行銷」**不等於**已符合 PDPA——Tryzeon 作為**資料控制者**，對自己直接蒐集的上傳照片負全責。
- **務必落地：** 上傳時明確知情同意；清楚的保留/刪除政策（建議自動刪除）；**未經另外同意不得拿人像做模型訓練**；加密儲存；內容安全護欄過濾未成年/裸露輸入。

**(B) 平台內容政策灰區**
- MINI App 條款禁止內容用語廣泛（違善良風俗/猥褻/有害第三人），**未明列** AI 人體影像細則，試穿產品落在判斷灰區。LINE 可在違規時**立即下架且不負責**。
- **緩解：** 上架前先與 MINI App 預審團隊 `dl_tw_miniapp_prereview@linecorp.com` 諮詢、預先送審內容模型。

**(C) 平台鎖定**
- MINI App 蒐集的使用者資料所有權歸 LINE（你直接蒐集的除外）。**緩解：** 核心試穿引擎保持薄抽象層、不要 LINE-only，保留可攜性。

**(D) 訊息成本隨 push 行銷線性放大**（詳見 §11）。

---

## 4. 市場現況：LINE 上的衣服「賣得到、卻試不到」

**LINE 上有在賣衣服嗎？有，服飾是 LINE 電商主力品類之一。** 分兩種模式：多數是「導購外連」（在 LINE 看到 → 跳轉品牌/商城官網結帳），少數是「站內成交」（直接在 LINE 內下單付款）。

| 通路 | 說明 | 結帳在哪 | 信心 |
|---|---|---|---|
| **LINE 購物（buy.line.me）** | 全台最大導購/比價平台，連 1,300+ 商店、3,200 萬商品；「流行時尚/服飾鞋包」是頂層分類，品牌含 GU、lativ、G2000、Roots、The North Face、Coach 等 | **外連**（跳蝦皮/momo/官網），回饋 LINE POINTS | 高 |
| **官方帳號開店幫手 / MyShop + SHOPLINE / meepShop / 91APP 串接** | 品牌在 OA 內開店，「看訊息→瀏覽→下單→付款」全程不離開 LINE；服飾/團購/韓貨代購是明列目標客群 | **站內成交**（LINE Pay/信用卡） | 高 |
| **LINE 禮物（giftshop）** | 可送服飾/鞋包/配件，有「國際時尚」分類（CHARLES & KEITH、Coach 等），但服飾庫存偏薄、以美妝/食品為主 | **站內購買** | 高 |
| **直播拍賣 / 社群 +1 團購** | OA + OpenChat 綁開店幫手「邊看邊買」，適合服飾連線/代購；OB嚴選累積 1,300 萬+ LINE 好友 | **站內成交**（部分外連） | 中 |

> **核心洞察：服飾品牌已大量進駐 LINE = 現成買家基礎**。1,000+ 品牌、流行服飾長期是 LINE 購物與 SHOPLINE 社群電商的銷售第一名，OB嚴選/UNIQLO 在 LINE 各有千萬級好友。**買家在、流量在、購買行為在，唯獨「試穿」這塊是空白。** 這正是 Tryzeon 要補的轉換工具缺口——和玩美把 AR 美妝試妝賣給彩妝品牌是同一套打法，只是品類換成服飾。

---

## 5. 競品分析：玩美移動（Perfect Corp）在 LINE 的整合

### 5.1 一句話定調
> **玩美在 LINE 上做的是「AR 彩妝試妝」，而且只有彩妝。** 技術是它的 YouCam WebAR，跑在 LINE TODAY 的站內瀏覽器網頁裡，當成「行銷產品」賣給美妝品牌——**不是 LIFF、不是 MINI App、不是聊天機器人**。

### 5.2 玩美是誰（重點摘要）
- 2015 由張華禎自訊連科技（CyberLink）分拆，總部新北新店；2022/10 經 SPAC 於 **NYSE 上市（代號 PERF）**。
- 營收約 US$60M（2024）→ 約 US$69M（FY2025），毛利約 77%，現金約 US$126M，服務約 800–860 個品牌客戶（涵蓋前 20 大美妝集團約 90%）。
- **兩條技術線（關鍵區分）：**

| 技術線 | 適用品類 | 機制 | 是否在 LINE |
|---|---|---|---|
| **即時 AR 疊圖**（非生成式） | 彩妝、眼鏡、髮色、珠寶、手錶 | 專利 AgileFace/AgileHand 即時追蹤，把效果幾何**疊**在使用者影像上（即時、不上傳） | ✅ LINE 上用的就是這條 |
| **生成式 AI 服飾試穿**（≠ AR） | 衣服（2025/5）+ 2026/1 再加 9 類 Fashion API（鞋/包/珠寶…） | 上傳一張照片 + 服飾圖 → **伺服器端生成**寫實穿著影像 | ❌ **未部署在 LINE** |

> **彩妝是把像素「疊」在臉上；服飾是把影像「重新生成」。** 這是不同技術家族——正是 Tryzeon 護城河論述的根基。

### 5.3 他們在 LINE 怎麼整合（端到端機制，高信心）

```
[版位層] LINE Biz-Solutions「AR 試妝體驗」（賣給美妝品牌的行銷產品）
         ・常駐跑在 LINE TODAY（LINE 自稱 1,800 萬+ MAU）
         ・入口靠編輯內容導流：今日排隊 → 潮流時尚 → AR 試妝美容室
              │  點品牌/商品
              ▼
[渲染層] 開啟 WebAR 試妝「網頁」（LINE 站內瀏覽器）
         ・連到品牌自架 landing，例如 linebc.yslbeauty.com.tw/web/youcam-mackup/...
         ・"linebc" = LINE Business Connect；"youcam" = 玩美引擎
              ▼
[技術層] 玩美 YouCam WebAR（免下載，瀏覽器內用鏡頭即時疊圖）
              ▼
[轉換層] 試色 → 挑選 → 一鍵跳「LINE 禮物」結帳，全程不出 LINE
```

- **商業包裝：** 以企業洽談（contact-to-quote）賣給美妝品牌，綁一整套 LINE 生態打法（OA + LAP 廣告 + 直播 + KOL），閉環收在 LINE 禮物。台灣萊雅曾以 18 個品牌帳號同時跑。
- **代表品牌：** 台灣萊雅 L'Oréal（旗艦案，得 LINE Biz-Solutions Awards 2025 金獎）、YSL、Giorgio Armani、PRADA BEAUTY。

> 信心校正：「站內瀏覽器網頁、非 LIFF」是由 URL 結構（一般 `.html`、無 `liff.line.me`、無 MINI App ID）**推論**，非 LINE/玩美明文聲明。

### 5.4 為什麼這對 Tryzeon 是結構性利多

| 維度 | 玩美 AR 彩妝 | Tryzeon 生成式服飾 |
|---|---|---|
| 輸入 | **即時鏡頭串流**（getUserMedia） | **上傳一張照片** |
| 處理 | 瀏覽器端內疊圖 | 伺服器端重新生成 |
| 適不適合 LIFF | **不適合**——LIFF webview 內 `getUserMedia` 取不到串流（LINE 官方 issue #98），只能用完整瀏覽器/LINE TODAY 網頁 | **天然適合**——只要 `<input type=file>` 上傳，不需即時相機串流 |

→ 玩美因依賴即時相機，被迫只能用站內瀏覽器網頁、做不出深度 LINE-native 整合；**Tryzeon 反而能用 LIFF/MINI App 做出更深的站內體驗**（OA + Rich Menu + LIFF + LINE 購物/禮物漏斗）。

### 5.5 戰略判定
- **類別空白成立（已對抗性查核）：** 截至 2026/6，LINE 台灣站內查無任何生成式全身服飾試穿。
- **論述紀律：** 正確差異化點是**「LINE-native 通路 + 台灣服飾部署」**，**不是**說「玩美做不到服飾生成」（他們有出貨，只是沒上 LINE）——後者會被打臉。
- **威脅 vs 市場驗證：判定為市場驗證 ＞ 正面威脅。** 但窗口非永久，玩美有能力也有動機把 Fashion API 移植上 LINE。
- **不要打的仗：** 玩美是 NYSE 上市、手握約 US$126M 現金的在位者，**燒錢/拚 logo 數打不贏**。Tryzeon 的真實護城河只有兩條：(1) 在 **LINE × 台灣成為服飾原生預設**，搶在在位者移植前；(2) **智慧衣櫥留存**——玩美的交易型試妝沒有對應物。

---

## 6. 可用的 LINE SDK / API 與整合方案全景

> 分層整理（身分層 → 體驗層 → 成交層 → 成長分銷層 → 廣告曝光層）。「適配」= 對 Tryzeon 契合度；「成本」= 採用工程/審核成本。

### 🔑 身分層
| 方案 | 是什麼 | 適配 | 類別 | 成本 | 現況註記 |
|---|---|---|---|---|---|
| **LINE Login（原生 flutter_line_sdk）** | OAuth2/OIDC，包進現有 Flutter app，取得 userId/暱稱/頭像（email 需審核） | **高** | 身分 | **低** | 與現有 Supabase PKCE + Apple/Google 同架構，可平行接上 |
| LINE 會員卡 / Profile+ | OA 內電子會員卡（CRM）；Profile+ 讓認證夥伴讀預填資料 | 低 | 身分 | 中 | 後期 loyalty；近期較可行是 MINI App Quick-fill（2025/8 GA） |

### 🎨 體驗層
| 方案 | 是什麼 | 適配 | 類別 | 成本 | 現況註記 |
|---|---|---|---|---|---|
| **LINE MINI App（認證版，優於純 LIFF）** | 同 LIFF 技術，認證後解鎖 LINE 內搜尋/Home 曝光、永久連結 miniapp.line.me、Service Messages | **高** | 站內 | **高** | 2025/10 LINE TAIWAN 轉「開放平台」+ 站內付款 + 廣告分潤，已有 100+ 台灣品牌；LINE 建議新 LIFF 一律以 MINI App 開發 |
| LIFF（純，未認證） | 在 LINE 內嵌瀏覽器跑 web app（getProfile/share/openWindow） | 高 | 體驗 | 低 | 免審核，最快上線；之後可 re-register 升級成 MINI App |

### 💰 成交層
| 方案 | 是什麼 | 適配 | 類別 | 成本 | 現況註記 |
|---|---|---|---|---|---|
| LINE Pay | LINE 金流站內結帳 | 中 | 站內成交 | 中 | 台/泰活躍（約 3% 費率），⚠️**日本 2025/4/30 終止** |
| Rich Menu + 開店幫手 storefront | OA 變商店（0% 手續費、直播/一鍵結帳）；Rich Menu 是 OA 底部常駐入口 | 中 | 站內成交 | 低 | Rich Menu 可當「試穿」入口導進 MINI App，再交棒結帳 |
| LINE 禮物 / GIFT | 社交送禮上架 | 低 | 站內成交 | 中 | 策展型目錄、非自助 API；屬後期成長 |
| LINE LIVE-commerce | 直播導購聊天內成交 | 低 | 站內成交 | 中 | ⚠️ 獨立 LINE LIVE 2023/3 已收，現走 OA 開店幫手直播 |

### 🚀 成長分銷層
| 方案 | 是什麼 | 適配 | 類別 | 成本 | 現況註記 |
|---|---|---|---|---|---|
| **Share Target Picker（liff.shareTargetPicker）** | 把試穿圖以 Flex 卡分享給好友/群組，深連回 App | **高** | 成長 | **低** | LINE 內最便宜的病毒迴圈；需 Console 啟用 + 用戶已登入 |
| **Service Messages（MINI App 限定推播）** | 交易型推播「你的試穿好了」，每動作最多 5 則 | **高** | 通知 | **低** | 嚴格限交易、**禁行銷**；完美契合非同步 tryon |
| LINE 購物 / SHOPPING | 全台最大導購（外連），SHOPLINE/meepShop 一鍵橋接 | 中 | 外連 | 低 | 無法站內渲染試穿，但是品牌變現主場 |
| OpenChat / LINE 社群 | 半匿名主題聊天室 | 低 | — | 低 | 無商務 API；穿搭分享社群的行銷戰術 |
| LINE Beacon / Touch | BLE/NFC O2O 觸發 | 低 | 通知 | 高 | 硬體相依；待實體零售夥伴出現再評估 |
| ~~LINE Notify~~ | 舊版 token 推播 | 低 | 通知 | — | ⚠️ **已停用（2025/4/1）**，改用 Service Messages / Messaging API push |

### 📢 廣告曝光層
| 方案 | 是什麼 | 適配 | 類別 | 成本 | 現況註記 |
|---|---|---|---|---|---|
| **LINE Tag + LINE Ads（LAP）** | 轉換/再行銷像素 + 自助投放（含 Dynamic Ads）；觸及 2,100 萬+ 台灣用戶 | **高** | 廣告 | 中 | 既有 `try_on`/`purchase_click` 事件可 1:1 對應；PROTOSTAR 廣告金可投入此處 |
| Smart Channel | 聊天列頂端高曝光廣告位 | 中 | 廣告 | 中 | 透過 LAP 投放 |
| LINE Business Connect / LINE TODAY WebAR | **售賣型媒體版位**（玩美機制），非開發整合 | 中 | 廣告 | 高 | ⚠️ 查無服飾公開案例；需 BD + 廣告預算 + 旗艦品牌，當燈塔行銷而非建置任務 |

> Messaging API（OA 聊天機器人）與純 LIFF 為使用者已知、本報告未重列，但兩者是把上述方案串起來的黏合層（詳見 §7）。

---

## 7. Tryzeon × LINE 整合藍圖（技術架構）

> 心智模型：**OA = 門面/通路/通知**、**LIFF/MINI App = 試穿體驗本體**、**Messaging API = 黏合劑 + 輕量試穿**。三者一起用，不是二選一。

### 整體分層架構

```
┌──────────────────────────────────────────────────────────────────────┐
│  使用者進入點                                                          │
│  (a) 既有 Flutter App        (b) LINE 聊天 / Rich Menu / LIFF / MINI   │
└───────────────┬───────────────────────────────┬──────────────────────┘
                │                                 │
   flutter_line_sdk (原生 LINE Login)     LIFF / MINI App (LINE 內嵌瀏覽器)
                │  idToken(ES256)                 │  liff.getProfile / <input type=file> 上傳照片
                ▼                                 ▼
        ┌───────────────────────────────────────────────────┐
        │           Supabase Edge Functions (Deno)          │
        │  • verify LINE id_token (oauth2/v2.1/verify)      │
        │    → 鑄造/連結 Supabase user                      │
        │  • Messaging API webhook 接收                      │
        │    （先驗 x-line-signature HMAC-SHA256 over raw    │
        │      body，驗證前勿 parse！）                       │
        │  • 託管/呼叫既有 tryon function（AI 生成）         │
        └───────────────┬───────────────────────────────────┘
                        │
            ┌───────────▼───────────┐        ┌──────────────────────────┐
            │  既有 tryon (AI 生成)  │───────▶│ Supabase Storage (結果圖) │
            └───────────────────────┘        └──────────────────────────┘
                        │
                        ▼
        回傳：reply 訊息（免費）+ image + Flex 商品卡 / LIFF 深連結
```

### (a) LINE Login 接既有 Supabase auth
Supabase **無內建 LINE provider**。推薦保留 `flutter_line_sdk` 原生登入，把 `idTokenRaw` 送 Edge Function 對 `POST https://api.line.me/oauth2/v2.1/verify` 驗證後，鑄造/連結 Supabase user（與現有 Apple/Google 原生流一致）。
> ⚠️ 原生 LINE id_token 是 **ES256**、純 web login 是 HS256；若改走 Supabase Custom OIDC + `signInWithIdToken`，與 LINE issuer 的相容性**需在測試專案實證**。

### (b) 試穿放進 LIFF / MINI App — 相機/上傳照片的明確結論
> **結論：用 `<input type="file" accept="image/*">` 上傳照片（可靠）；不要依賴 LIFF 內嵌瀏覽器的即時 `getUserMedia` 相機串流（iOS/Android webview 不保證）。**
- 必須 **HTTPS / secure context**。
- Tryzeon 的「上傳照片 → 伺服器生成」模式正好避開 LIFF 即時相機的不確定性。重 ML 一律留伺服器端（既有 tryon），別放進 webview。
- 若真需即時 AR 相機：用 `liff.openWindow({external:true})` 開系統瀏覽器，或在原生 Flutter App 內拍攝。
- **上線前務必用最新版 LINE 實機測 iOS/Android 的 `<input type=file>` 行為。**

### (c) Messaging API + Flex「傳照片 → 回試穿結果」機器人
```
使用者在 OA 傳一張人像照
        │  LINE POST webhook（message type=image）
        ▼
Edge Function：① 先驗 x-line-signature（HMAC-SHA256 over RAW body，驗證前勿 parse！）
        ▼
② 用 message-content 端點抓二進位圖 → ③ 呼叫既有 tryon 生成
        ▼
④ 回傳（reply token，免費）：image 訊息 + Flex 輪播商品卡 + Rich Menu
```
- **成本關鍵：** 用 **reply**（免費、不計額度）回覆，核心試穿對話邊際成本趨近零。
- ⚠️ **非同步陷阱：** 若生成較久、reply token 視窗過期，得改用 **push（計費）** 通知結果——盡量在 token 視窗內完成，或縮短生成時間。MINI App 情境改用 **Service Messages**。

### (d) 病毒成長
- LIFF/MINI App 內：`liff.shareTargetPicker(messages)` 開好友/群組選擇器發送自訂 Flex 卡（最多 5 則）。
- 原生 Flutter App：用 `line://msg/...` URL scheme 或平台分享面板。

### (e) 店家側
- **OA 商店**（開店幫手）做商品/訂單/客服；**LINE Pay** 結帳；**LINE 購物** 導購曝光（深連回試穿 LIFF）；**LINE Tag** 量測「試穿→購買」漏斗。

### (f) Supabase Edge Functions 角色
1. **Messaging API webhook 接收器** — 讀 raw body、先驗 `x-line-signature`（HMAC-SHA256，channel secret 為 key），constant-time 比對；**任何在驗證前的 parse/改寫都會破壞簽章**。
2. **LINE Login id_token 驗證** — 對 `oauth2/v2.1/verify` 驗證後鑄造/連結 Supabase user。
3. **託管/呼叫既有 `tryon` function** — 現有管線不變。
4. 與既有 **RevenueCat webhook** 同層共存。
> ⚠️ **付費模式衝突：** 若走 MINI App 在 LINE 內購買（2025/10 後），須用 LINE 應用內付款，與現行 RevenueCat / App Store 訂閱帳本不對帳——需另建 entitlement 同步路徑（費率/分潤%未公開）。

---

## 8. ⭐ 總體推薦發展路線（序貫組合三階段）

### 定調：**「以 MINI App 為終局核心、但用速度路線開場」——分階段序貫組合，不是二選一。**

由三位評審（速度 / 通路 / 護城河，皆 8/10 信心）收斂得出：**認證版 LINE MINI App 是不可迴避的核心表面、LINE Login 是不可迴避的第一步。** 真正要決策的只有一件事——**何時付「認證審核」這個唯一關卡成本。** 裁決：**先用速度路線拿數據與漏斗，再用通路路線的引擎放大，護城河的衣櫥留存 + Service Messages 全程貫穿。**

| 路線 | 主軸 | 信心 | 採納其 |
|---|---|---|---|
| 衝刺速度 | LINE Login 原生 + 純 LIFF（刻意延後認證），掛 LINE Tag + 分享迴圈，數據先行 | 8/10 | **開場洞見**：幾乎零成本、免審核 |
| 通路擴散 | 認證 MINI App 當「服飾試穿轉換單元」，PROTOSTAR 廣告金灌 LINE Tag + LAP 驅動品牌 SKU 轉換 | 8/10 | **放大引擎** |
| 護城河深度 | 認證 MINI App + 站內衣櫥留存迴圈 + Service Messages 再互動，搶「LINE 預設服飾試穿」 | 8/10 | **全程黏著** |

### 🚫 明確「暫不做」清單（避免分散）
| 不做 | 為什麼 |
|---|---|
| **LINE Business Connect / LINE TODAY WebAR 售賣媒體** | 是買媒體不是寫程式；且 Tryzeon 是上傳後生成非即時 AR。當遠期燈塔行銷，別當建置任務 |
| **第一階段就衝 MINI App 認證** | 認證是唯一審核關卡，會卡開場。等數據證明需求再送 |
| **LINE Pay** | 僅在自售 SKU/試穿額度/抽成時才需要；目前外連導購 + RevenueCat 已處理訂閱，不在關鍵路徑 |
| **LINE 禮物 / 會員卡 / Profile+ / Beacon / OpenChat / 直播** | 全屬後期 upsell、loyalty 或實體零售，需 BD/硬體 |
| ~~**LINE Notify**~~ | 已停用，勿觸碰；通知用 Service Messages 或 Messaging API push |

### 一句話定調
> **先用「LINE Login + 免審核 LIFF + LINE Tag/分享迴圈」幾週內量出真實試穿漏斗，再把同一個 web app 升級成認證 MINI App 並接上 Service Messages 衣櫥留存——MINI App 是終局核心，但讓數據而非審核排程決定你何時抵達。**

---

## 9. 分階段落地計畫（Roadmap）

> 工時為量級估計（人日），非精確報價；依團隊熟悉度浮動。

### Phase 0 — 申請前準備（~1–2 週）
| 工作項 | 量級 |
|---|---|
| 向 `dl_protostar@linecorp.com` / 官網查證 2026 報名狀態、條款、文件清單 | 0.5d |
| 台灣公司登記確認（5 年內 / A 輪前 / 未上市） | — |
| 一頁 traction deck（含 §10 KPI） | 2–3d |
| PDPA 同意書 + 照片自動刪除政策 + 內容安全過濾草案 | 2–3d |
| 與 MINI App 預審 `dl_tw_miniapp_prereview@linecorp.com` 預諮詢內容政策 | 0.5d |

### Phase 1 — MVP-on-LINE（~1–3 週，零審核、近零成本）：身分 + 免審核試穿 + 量測
| 工作項 | 量級 |
|---|---|
| LINE Login channel + `flutter_line_sdk` 原生登入接 Supabase（Edge verify） | 3–5d |
| 純 LIFF 試穿 web 前端（`<input type=file>` 上傳 → Storage → 既有 tryon） | 5–8d |
| OA（免費輕用量）+ Messaging webhook（簽章驗證）+「傳照片→回結果」reply 流 | 5–8d |
| Flex 商品卡 + Rich Menu（開始試穿/衣櫥/商店） | 3–5d |
| LINE Tag（`try_on`/`purchase_click` 對應）+ `liff.shareTargetPicker` 分享 | 2–3d |
| 實機測試 iOS/Android 上傳行為、生成 < 30s | 2–3d |
> 產出：一條可量測的「獲客→試穿→分享→購買點擊」漏斗 = 需求證據 + PROTOSTAR 簡報數據。

### Phase 2 — 升級認證 MINI App + 留存推播（~4–10 週，有數據撐腰）
| 工作項 | 量級 |
|---|---|
| 把**同一個** LIFF **送 MINI App 認證**（re-register 而非重建），解鎖搜尋/Home 曝光 + 永久 miniapp.line.me 連結 | 5–10d + 審核 |
| 接 **Service Messages**：tryon 完成推「你的試穿好了」+ 站內**衣櫥留存迴圈** | 3–5d |
| 申請**藍盾驗證 OA**（台灣公司 + 專屬 ID NT$720/年）解鎖加好友廣告 | 2–3d + 審核 |

### Phase 3 — 放大與成交（~3–6 月）
| 工作項 | 量級 |
|---|---|
| PROTOSTAR 廣告金投 **LAP 獲客 + Dynamic Ads** 再行銷「試穿未買」 | 持續 |
| 店家側自助品牌 SKU 上架漏斗，經 `product.purchaseLink` 外連品牌店 / LINE 購物 | 5–10d |
| 爭取**一個旗艦服飾品牌**做燈塔共行銷案例 | BD |
| 評估 MINI App 應用內付款 vs RevenueCat 的 entitlement 同步 | 視 LINE 條款 |

---

## 10. 提案 Pitch 重點與 KPI

### 怎麼框定才會被選上
1. **以類別差異化定位，不打彩妝。** 一句話打法：「玩美把美妝 AR 試穿教給了 LINE 的品牌；Tryzeon 補上美妝 AR 做不到的**服飾/全身穿搭生成式試穿 + 智慧衣櫥**。」明說玩美是市場驗證者而非要打的對象。
2. **複製玩美的 Go-to-Market，而非其品類。** 把試穿當成賣給服飾品牌/零售的 LINE 行銷轉換產品；用既有店家端做品牌 SKU 上架；用「轉換提升/退貨下降/互動」的數字敘事。
3. **打技術適配牌。** Tryzeon 的「上傳照片 → 伺服器生成」天然吃 LIFF webview，而玩美即時 AR 受 `getUserMedia` 限制——Tryzeon 能做更深的 LINE-native 站內體驗。
4. **打「先發鎖定」時間牌。** 搶在玩美把 Fashion API 移植上 LINE 之前，用 PROTOSTAR 鎖定首批 LINE 服飾品牌，並以**衣櫥留存**築玩美沒有的護城河。
5. **回答 LINE 三問：** 在 LINE 上做什麼（生成式試穿 LIFF/MINI App）／合作後突破（LINE 補上服飾生成試穿品類）／為什麼是你（自有 tryon 生成管線 + 已上線產品 + 智慧衣櫥資料）。

> ⚠️ 論述紀律：差異化在「LINE-native 服飾通路 + 台灣部署」，**不要**宣稱玩美沒有服飾生成能力。簡報前先掃 LINE 最新案例庫確認沒有同類生成式服飾案例。

### 建議主打 KPI
| 類別 | 指標 |
|---|---|
| 互動/留存 | WAU/MAU、留存曲線 |
| 產品價值 | 每使用者試穿次數、生成時間（目標 < 30s） |
| 轉換 | 試穿 → 購買點擊轉換率 |
| 成長經濟 | 加好友成本 vs LTV、分享率（shareTargetPicker） |
| 商家價值 | 上架店家/SKU 數、預估 LINE Pay GMV |

---

## 11. 成本與限制

### LINE 官方帳號台灣方案（須以 tw.linebiz.com 即時為準；含第三方來源）
| 方案 | 月費（未稅） | 免費 push 訊息/月 | 加購 |
|---|---|---|---|
| 輕用量 Light | NT$0 | 200 | ❌ 不可加購（超量即報錯） |
| 中用量 Medium | ~NT$800 | 3,000 | ❌ 不可加購 |
| 高用量 High | ~NT$1,200 | 6,000 | ✅ 階梯遞減，約 NT$0.2/則起 |

- **計費關鍵：** 只有 **push/multicast/broadcast/narrowcast** 計入額度；**reply、1:1 聊天、歡迎訊息、關鍵字自動回應全免費不計**。按收件人數計。
- **平台本身免費：** Messaging API / LINE Login / LIFF 無平台費。成本只來自 OA 訊息方案與專屬 ID。
- ⚠️ NT$800 / NT$1,200 等數字含第三方來源且 LINE 會改版，編列預算前**務必到 tw.linebiz.com/faq/oa-price 確認**。

### 其他
- **MINI App：** 開發零費用；發布審查約 5–10 工作天；Verified 需先成為認證供應商。
- **藍盾驗證 OA：** 需台灣登記公司 + 專屬 ID NT$720/年（網頁購買）。
- **LINE Pay：** 商店申請免設定費；費率約 3%（含稅約 3.15%）；撥款 T+2；審核約 7–10 天。

### 主要平台風險（彙整）
1. **訊息成本隨 push 放大**：核心試穿用 reply 近免費，但 push 再行銷線性計費。
2. **平台鎖定**：MINI App 蒐集資料所有權歸 LINE、LINE 可隨時下架。
3. **審核/驗證 gating**：Verified MINI + 藍盾需台灣公司、認證供應商、5–10 工作天審查，且可能被廣義「猥褻/有害」條款拒絕——身體影像產品需強護欄。
4. **PDPA/內容曝險**：人像為敏感資料，同意/保留/訓練再用處理不當有法律與下架風險。
5. **付費模式衝突**：MINI App 應用內付款與 RevenueCat 不對帳，需另建同步。

---

## 12. 下一步行動清單（Checklist）

1. **查證報名狀態（本週）** — 寄 `dl_protostar@linecorp.com` 詢問 2026 核心孵化軌是否收件、截止日、必繳文件、是否需台灣法人；看 `protostar.line.me`。
2. **內容政策預諮詢** — 寄 `dl_tw_miniapp_prereview@linecorp.com`，說明「上傳人像 → AI 生成試穿」，問是否可過 Verified MINI 審核。
3. **建 LINE Developers channel** — 到 `developers.line.biz` 建 **LINE Login channel**（給 flutter_line_sdk）與 **Messaging API channel**（OA）。
4. **OA 開帳（輕用量免費）** — `tw.linebiz.com`，先用免費輕用量。
5. **Phase 1 MVP** — 原生 LINE Login → Supabase（Edge verify）；純 LIFF 試穿前端用 `<input type=file>`；Messaging webhook（先驗 `x-line-signature`）→ reply 回 Flex 結果卡；LINE Tag + `shareTargetPicker`。
6. **實機驗證** — 在當前 iOS/Android LINE 版本測 `<input type=file>` 行為。
7. **法遵文件** — 完成 PDPA 同意書、照片自動刪除政策、未成年/裸露內容過濾，部署於上傳流程第一天。
8. **traction deck + KPI** — 整理 WAU/MAU、試穿→購買轉換、分享率、預估 GMV，主標設為「填補 LINE 生成式服飾試穿空白」。
9. **Phase 2/3 觸發** — 通過後送 MINI App 認證、辦藍盾、用 NT$30 萬廣告額度 + LINE Tag 再行銷、店家側上 LINE Pay / LINE 購物。

---

## 13. 需查證清單（彙整）

| 待查項 | 為何不確定 / 查證管道 |
|---|---|
| 2026 報名是否開放、截止日、必繳文件、是否需台灣法人 | 公開頁採滾動收件；`protostar.line.me`、`dl_protostar@linecorp.com` |
| **NT$30 萬廣告資源**是否仍為現值 | 源於 ~2020 報導；直接問 LINE |
| **PROTOSTAR 廣告金能否投 LAP/LINE Tag** | 「可投 LAP」是合理推論非官方明列；這是整個放大引擎的金流前提，務必確認 |
| 續年免費 OA 換股權的具體比例/估值 | 官方未揭露；與 LINE 談判確認 |
| **MINI App 變現的地區差異**（站內 IAP=日本、LINE Pay=台/泰、廣告分潤=台灣） | 易被二手來源混淆；對照 LINE 台灣官方 dev/biz 頁 |
| 玩美是否為 LINE AR 試妝**獨家**技術商；L'Oréal 案是否確由玩美驅動 | bnext 報導全文未提玩美；向 L'Oréal/玩美求證 |
| 「玩美 LINE 整合 = 站內瀏覽器 WebAR、非 LIFF」 | 由 URL 結構推論，非明文 |
| LINE TODAY WebAR / Business Connect 服飾案例 | 查無服飾公開案例（類比驗證，信心中） |
| 最新版 LINE 的 LIFF/iOS WKWebView `getUserMedia` 與 `<input type=file>` 行為 | 跨版本會變；上線承諾前逐版實測 |
| LINE 服飾類 GMV / 站內成交服飾商家數 | LINE 未公開；勿引用精確數字 |
| 「LINE 無原生服飾試穿」 | 搜尋無結果的負面證據；正式簡報前人工掃 LINE 購物/品牌 OA/MINI App 目錄 |
| Supabase Custom OIDC 與 LINE issuer（ES256）端到端相容性 | 需測試專案實證 |

---

## 14. 附錄：關鍵官方查證連結

- PROTOSTAR：`https://protostar.line.me/` ／ `dl_protostar@linecorp.com`
- MINI App 預審：`dl_tw_miniapp_prereview@linecorp.com`
- LINE Developers：`https://developers.line.biz/`（Login / LIFF / Messaging / MINI App）
- OA 方案/費率：`https://tw.linebiz.com/faq/oa-price/`
- LINE Pay 商店：`https://developers-pay.line.me/online`
- LIFF 內嵌 vs 外部瀏覽器：`https://developers.line.biz/en/docs/liff/differences-between-liff-browser-and-external-browser/`
- flutter_line_sdk：`https://pub.dev/packages/flutter_line_sdk`
- LINE 購物：`https://buy.line.me/`
- 玩美移動 Business：`https://www.perfectcorp.com/business`

> **誠實提醒：** 本報告中所有 NT$ 金額、報名梯次/截止日、福利現值、MINI App 付款分潤%、競品歸屬，皆需以上列官方管道**最終確認**後再寫進正式申請與預算——研究資料部分來自 2020 年報導與第三方來源，可能已變動。
