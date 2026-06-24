# Tryzeon × NVIDIA Inception 研究報告

> **產出日期**：2026-06-24
> **研究方法**：5 個搜尋角度 → 抓 18 個來源 → 抽 80 條主張 → 對其中 25 條做 3 票對抗式查證（need 2/3 反駁才淘汰）→ 25 條全數確認、0 條被推翻。
> **信心標註**：標 `medium` 的主張為單一新聞稿來源，請當作參考而非合約；金額/折扣百分比多為第三方來源，屬指標性數字。

---

## 核心結論（TL;DR）

1. **Inception 門檻很低、值得投**：免費、不收費、不拿股權、無截止日、無梯次（cohort）。只要「已公司化 + 成立未滿 10 年 + 至少 1 名開發者 + 有可運作的網站/App」就符合資格 —— Tryzeon 幾乎肯定過得了這四關。
2. **虛擬試穿是 NVIDIA「官方背書」的用例**：NVIDIA 自家的 *Retail Shopping Assistant AI Blueprint* 明確內建 virtual try-on，且 2026/03 有 CATCHES「RealFit」時尚試穿產品打著 "Powered by NVIDIA"。申請時可直接對齊這條敘事線。
3. **整合幾乎是 drop-in**：NVIDIA 的 NIM 影像編輯模型（FLUX.1 Kontext / Qwen-Image-Edit）提供 **OpenAI 相容的 Image Editing API**。Tryzeon 現在 `supabase/functions/tryon/image.ts` 裡呼叫 Vertex 的那段 `fetch`，可換成呼叫 NIM 端點，prompt 工程大致沿用。
4. **最強申請策略**：把 Tryzeon 定位成「生成式 AI 影像/擴散模型新創」，roadmap 寫明「採用 NIM 做試穿推論、對齊 NVIDIA 零售 Blueprint」，並用 Inception 額度 + DGX Cloud Innovation Lab 把 garment-swap 推論搬上 NVIDIA GPU。

---

## Part 1 — NVIDIA Inception 是什麼、怎麼申請

**本質**：不是傳統育成器（accelerator），比較像「免費的開發者 + 商務資源會員制」。

| 項目 | 內容 |
|---|---|
| 費用 | **完全免費**，無申請費、無會員費 |
| 股權 | **不拿股權** |
| 時程 | 無截止日、無梯次，隨時可申請 |
| 資格（4 關，需全部符合） | ① 已正式公司化 ② 成立 **< 10 年** ③ **至少 1 名開發者** ④ 維護一個可運作的網站 |
| 營收要求 | **不需要營收**，各融資階段皆可（pre-seed 也行） |
| 排除對象 | 上市公司、加密貨幣公司、雲端服務商、轉售商、顧問公司 |
| 申請方式 | 線上入口（`programs.nvidia.com`）：上傳 pitch deck、確認公司化/網站等資料 |

> ⚠️ **Tryzeon 唯一要先確認的是「已公司化」**。若還沒成立法人實體，這是申請前唯一的硬前提。其餘三關（< 10 年、有開發者、有可運作 App）都已滿足。

來源：`nvidia.com/en-us/startups/`、`/showcase/`（皆 primary）。

---

## Part 2 — 加入後拿得到什麼福利

對 Tryzeon 最有價值的四類資源：

1. **雲端額度（Cloud Credits）** — 來自 NVIDIA 與合作夥伴。第三方資料指 AWS Activate 最高 ~$100k、Nebius 最高 ~$150k。
   - *caveat：額度大多來自「合作夥伴」而非 NVIDIA 直給，金額為第三方來源，請當指標性數字。*
2. **優惠定價（Preferred Pricing）** — 對「部分」NVIDIA 硬體/軟體的 rebate（從標準價折抵）。第三方稱硬體（A100/H100/RTX A6000 等）約 ~30%、軟體（如 Omniverse）約 ~70%。
   - *caveat：僅限「select」品項、可變動。*
3. **獨家夥伴優惠** — 工具、服務、支援。
4. **VC 曝光** — *Inception Capital Connect* / *VC Alliance*（200+ 投資人，含 Coatue、Mayfield、Menlo Ventures、General Catalyst、Conviction）+ 策展型 networking 活動。對募資是純加分。

**另外一個關鍵資源（需另外申請）：DGX Cloud Innovation Lab**

> 給「部分」Inception 會員的 **2 個月**動手實作期：NVIDIA 加速運算 + 整合 AI 軟體 + **專家支援**。需**另外提一份申請**，滾動審查、依名額與適配性核准（被拒後 3 個月可再申）。
> 入口流程：Portal → Profile → Add product → Benefits → Innovation Lab tile → Request Benefit。
> 這是 Tryzeon 拿到 GPU + NVIDIA 工程師協助、把試穿推論真的搬上去的具體管道 —— 但不保證一定拿得到。

來源：`nvidia.com/en-us/startups/`、`/showcase/`、`/venture-capital/`、`nvidia.com/en-us/data-center/dgx-cloud/innovation-lab/`。

---

## Part 3 — 適合虛擬試穿的 NVIDIA 技術棧

### 3a. NIM（NVIDIA Inference Microservices）— 主要整合點

把 AI 模型打包成「預先優化的 GPU 容器微服務」（模型權重 + 自動選擇的推論引擎 TensorRT-LLM/vLLM/SGLang + 標準 API），單一指令部署，可跑在雲/資料中心/工作站/邊緣。

**NIM for Visual Generative AI** 直接提供試穿會用到的擴散模型，每個都是可部署的 NGC 容器：

- **影像生成**：Stable Diffusion 3.5 Large、FLUX.1-dev、FLUX.1-schnell、FLUX.2-klein-4B、Qwen-Image
- **影像編輯（⭐ 試穿的核心操作）**：
  - **FLUX.1 Kontext-dev** — 影像條件式編輯/inpainting，主打**角色/物件一致性**、風格轉換
  - **Qwen-Image-Edit**（20B）— 語意 + 外觀編輯，「在保留其他區域不變的前提下增/刪/改元素」

> 「把人物照編輯成穿上新衣服、同時保留臉/身體/姿勢」正是 FLUX.1 Kontext / Qwen-Image-Edit 設計的場景，也已有第三方（a2e.ai、HF crossimage-tryon-fluxkontext、arXiv RefTon）拿這兩個模型做 garment-swap。
> ⚠️ 誠實標註：NVIDIA **沒有**賣「現成的試穿 NIM」，「適用於試穿」是基於技術 + 第三方實作的合理推論，不是 NVIDIA 行銷宣稱。

### 3b. OpenAI 相容 API — 整合的關鍵槓桿

NIM for Visual GenAI 提供 **OpenAI 相容的 Image Generation API 與 Image Editing API**（`/v1/images/...`）。可選：

- **雲端託管**：`base_url = https://integrate.api.nvidia.com/v1` + `nvapi-` key（適合快速原型）
- **自架**：每個模型是一個 Docker 容器，暴露同一套 OpenAI 相容 REST API（適合上線、控制隱私/吞吐）

### 3c. 規模化：Triton + TensorRT

NVIDIA Triton 有官方教學部署 Stable Diffusion 1.5 / SDXL（用 TensorRT pipeline）。領先的開源試穿模型（**IDM-VTON、OOTDiffusion**）都是 SD-class，所以若 Tryzeon 之後要自架/微調自己的擴散模型，這是有文件、GPU 優化過的上線路徑。
*caveat：Triton 已改名 "Dynamo-Triton"，教學容器版本鎖定（24.08 / TensorRT 10.4），但教學仍有效。*

### 3d. 原型沙盒：Brev / Launchables

**NVIDIA Brev** 在第三方雲（AWS/GCP/Lambda/Nebius/Oracle/Crusoe/Hyperstack 等）一鍵開 GPU 實例，環境（Python/CUDA/Docker/Jupyter）自動裝好；**Launchables** 給你「一鍵跑 NIM 微服務 + NVIDIA Blueprints」。是 Tryzeon 在投入基礎建設前，最低摩擦驗證 NIM 試穿推論的地方。

### 3e. NVIDIA 對 try-on 的官方背書（申請說服力來源）

- **Retail Shopping Assistant AI Blueprint**（建在 NVIDIA AI Enterprise + Omniverse 上）**明確內建 virtual try-on**，由 SoftServe 在 NRF 2025 展示。技術棧：NIM（Llama 3.3 70B*）+ NeMo（理解文字+影像 prompt）+ NeMo Retriever + NeMo Guardrails + SDXL + Riva。
  - *caveat：這是新聞稿；GitHub repo 內部已演進為 Nemotron 3 Super-120b + NV-CLIP —— Blueprint 內容會變。*
- **CATCHES「RealFit」× AMIRI（2026/03，"Powered by NVIDIA"）** — 建在 CUDA + Omniverse libraries + Newton Physics Engine，結合自訓擴散模型 + 微調 VLM/LLM（基於 **Nemotron** 與 **Cosmos** world foundation models）。
  - *信心 medium：主來源是廠商 PR，技術清單可信但「鏡面級擬真」這類形容請打折；Business of Fashion 有獨立佐證。*

---

## Part 4 — Tryzeon 現況 → 怎麼接進去（具體到程式碼）

**現況**（讀自 `supabase/functions/tryon/image.ts`）：

```
tryon Edge Function (Deno/TS)
  └─ generateTryonImage()
       └─ fetch → Vertex AI  gemini-2.5-flash-image :generateContent
            input:  人物圖(base64) + N 件衣服圖(分組) + 文字 prompt
            config: responseModalities:["IMAGE"], aspectRatio 9:16
            output: base64 圖
```

這是一個 **多圖條件式影像編輯** 任務 —— NVIDIA 對應物就是 **NIM 影像編輯模型**（FLUX.1 Kontext / Qwen-Image-Edit）走 **OpenAI 相容 Image Editing API**。

**整合方式（侵入性最小）：保留整個 `tryon` 函式當 orchestrator，只換 `generateTryonImage()` 裡那段 `fetch`。**

- Edge Function 流程、garment grouping、`buildTaskPrompt()`（那套很細的 scope/invariant 規則）**全部沿用** —— 因為 NIM 影像編輯一樣吃「文字 prompt + 條件圖」。
- 把對 Vertex `:generateContent` 的呼叫，換成對 NIM 端點的 `/v1/images/edits`（OpenAI 相容）呼叫：原型期用 `integrate.api.nvidia.com` + `nvapi-` key；上線用自架容器的內部端點。
- Supabase 內建的 `Supabase.ai.Session("gte-small")` 只適合輕量 embedding，**不要**拿來做重的試穿生成 —— 重活一律送 NIM。

> ⚠️ **必須先做 spike 驗證的兩個現實風險**（工程綜合推論，非已測過的端到端結論）：
> 1. **多圖條件 + 身分保留品質**：現在丟「人物 + 多角度多件衣服」給 Gemini。FLUX.1 Kontext 對多圖條件支援有限；Qwen-Image-Edit-2509+ 才支援多圖編輯。換過去後，「臉/姿勢不變 + 衣服精準轉移」的品質**不保證 ≥ Gemini**，要實測比對。
> 2. **隱私/SLA**：使用者上傳的是**身體照**。雲端託管 NIM（`integrate.api.nvidia.com`）的 rate limit、production SLA、資料隱私條款是否可接受消費級使用？若不行，就得**自架 NIM 容器**控制隱私與吞吐。

> **老實說**：目前 Gemini 方案是能用的。換 NVIDIA 不必然「產品更好」，它的價值在 **(a) 申請敘事 + (b) 用 credits 攤平 GPU 成本 + (c) 對齊 NVIDIA 生態**。因此下面 roadmap 設計成「**低風險先拿福利，再決定要不要真的搬遷推論**」。

---

## Part 4.5 — FAQ：需要「整合 CUDA」嗎？

**短答：在建議路徑裡，不需要你自己寫或整合 CUDA。** CUDA 是 GPU 的程式設計/執行層，NIM 的設計目的就是把 CUDA / TensorRT 封裝在容器內，對外只給 HTTP API（官方說法：NIM "abstracts away model inference internals"）。要不要碰 CUDA，取決於走到哪一層：

| 路徑 | 要不要碰 CUDA |
|---|---|
| **① 雲端託管 NIM（建議起手式）** | ❌ 完全不用。`tryon` Edge Function 只發 HTTP 到 `integrate.api.nvidia.com`，GPU/CUDA/TensorRT 全在 NVIDIA 那邊。 |
| **② 自架 NIM 容器（控隱私/吞吐）** | ⚠️ 只需在主機裝 **NVIDIA 驅動 + nvidia-container-toolkit**（讓 Docker 看得到 GPU）；CUDA/TensorRT 引擎**已包在 NIM 容器內**，你只是 `docker run`，**不寫 CUDA**。Brev / Launchables 會自動裝好這層。 |
| **③ 自訓模型 / Omniverse / 物理引擎（CATCHES 那條）** | ✅ 才會接觸 CUDA 生態，但多半透過 **TensorRT 工具鏈（Python/CLI）**，很少手寫 CUDA C++ kernel。屬進階、可選、非 MVP 必需。 |

**對 Tryzeon 的兩個具體含義：**

1. **codebase 本來就放不了 CUDA**：Flutter（手機端）+ Supabase Edge Functions（Deno/TS，無 GPU runtime）都不接觸 GPU。所有 GPU/CUDA 工作都在「HTTP 邊界的另一側」，所以「在 repo 裡整合 CUDA」本身不成立、也不需要。
2. **Inception 申請不需要 demo CUDA 整合**：審查看的是你會不會用 NVIDIA 的**推論服務（NIM）/ Blueprint / 加速基礎設施**，不是底層 CUDA 工程。敘事講「採用 NIM 做試穿推論」就夠分量。

> **一句話**：MVP 跟申請階段，一行 CUDA 都不用碰。真正要寫 CUDA 的場景（自訂 kernel、自訓模型優化）是很後期、且大多數試穿產品根本走不到的深度。

---

## Part 5 — 建議 Roadmap

| 階段 | 動作 | 目的 / 產出 |
|---|---|---|
| **0｜前置** | 確認 Tryzeon 已公司化；備妥 pitch deck + 上線 App 連結 | 滿足 Inception 4 關資格 |
| **1｜申請（先做、零成本）** | 用 Part 6 敘事，從 `programs.nvidia.com` 投 Inception | 拿到會員 → 解鎖 credits / 優惠價 / VC 曝光 |
| **2｜原型 spike（1 週）** | 在 **Brev / Launchable** 開 GPU，跑 FLUX.1 Kontext + Qwen-Image-Edit NIM，丟 5–10 組真實 (人物 + 衣服) 跑試穿，對比目前 Gemini 的品質/延遲/單張成本 | 用數據回答「該不該搬」—— 驗證 Part 4 兩個風險 |
| **3｜接線（若 spike 過關）** | 在 `image.ts` 加一個 `TRYON_PROVIDER` 開關：`vertex`（現況）/ `nim`（新）。NIM 分支呼叫 OpenAI 相容 Image Editing API。先雲端託管 | 可灰度切換、可回退，不賭單一供應商 |
| **4｜DGX Cloud Innovation Lab** | 另外提一份 Innovation Lab 申請，拿 2 個月 GPU + NVIDIA 專家，協助微調試穿模型 / 上 Triton | 把試穿推論「真的」搬上 NVIDIA 加速基礎設施 |
| **5｜規模化（看 unit economics）** | 隱私/吞吐需要就自架 NIM 容器；要自訓/微調擴散模型就上 **Triton + TensorRT**（參考 IDM-VTON/OOTDiffusion 這類 SD-class） | 成本可控、可長期經營的上線架構 |

---

## Part 6 — 申請敘事建議（怎麼寫才打中 NVIDIA）

把 pitch 寫成「**我們是生成式 AI 影像/擴散模型新創，做時尚虛擬試穿**」，並明確對齊 NVIDIA 在賣的東西：

1. **產品**：Tryzeon — AI 虛擬試穿 + 衣櫥管理（Flutter + Supabase，已上線、有真實用戶/分析數據）。
2. **技術 roadmap（關鍵段落）**：「採用 **NIM 影像編輯微服務**（FLUX.1 Kontext / Qwen-Image-Edit）做試穿推論；架構**對齊 NVIDIA Retail Shopping Assistant Blueprint** 的 virtual try-on 能力；以 **Triton + TensorRT** 規模化擴散模型服務。」
3. **可比案例**：引用 **CATCHES RealFit（Powered by NVIDIA）** 證明「NVIDIA × 時尚試穿」已是被驗證、且當下進行中的模式。
4. **要的東西具體化**：明說要用 **Inception cloud credits + DGX Cloud Innovation Lab** 把 garment-swap 推論搬上 NVIDIA GPU —— 讓 NVIDIA 看到你會用他們的運算。
5. （加分）若願意走 **Omniverse / 3D 數位人 / 物理試穿尺寸**（SoftServe / CATCHES 那條），是更深的對齊 —— 但成本高，建議當「未來選項」而非第一版承諾。

---

## 重要 Caveats（請在申請/動工前複查）

- **NIM 模型 ID 會輪替**：FLUX.2-klein-4B、qwen-image-edit-2511、SD 3.5 Large 等綁 NVIDIA「latest」文件（mid-2026 狀態），動工時請重查「Supported NIMs」表。
- **金額/折扣是第三方數字**：$100k AWS / $150k Nebius、~30% 硬體 / ~70% 軟體 —— 指標性、非合約，NVIDIA 可改。
- **Innovation Lab 不保證**：Inception 會員 ≠ 一定拿到 Lab GPU，要另審、看名額與適配。
- **「適用試穿」多為技術推論**：NVIDIA 沒有 turnkey「試穿 NIM」；整合食譜是跨已驗證能力的工程綜合，**務必用 Brev spike 實測**再決定。

## 留給你的開放問題（spike 要回答的）

1. NIM 影像編輯模型跑一張 garment-swap 的**延遲 / GPU 單張成本**，對比現在 Gemini 的品質與單位經濟學？
2. 雲端託管 NIM 的 rate limit / SLA / **身體照隱私條款**是否夠消費級用？還是必須自架？
3. 一個 Flutter+Supabase 消費級 App 進 Inception、以及拿到 Innovation Lab 的**實際核准機率與等待時間**？
4. **Omniverse / 3D 數位人 / 物理尺寸**對 Tryzeon 的 ROI，是否值得？還是純 2D 擴散/影像編輯（NIM）是更高 CP 值的路？

---

## 來源（primary 為主）

- **NVIDIA Inception**：`nvidia.com/en-us/startups/`、`/showcase/`、`/venture-capital/`
- **DGX Cloud Innovation Lab**：`nvidia.com/en-us/data-center/dgx-cloud/innovation-lab/`
- **NIM**：`nvidia.com/en-us/ai-data-science/products/nim-microservices/`、`docs.nvidia.com/nim/visual-genai/latest/`（overview + openai-image-generation）
- **Triton / Stable Diffusion**：`docs.nvidia.com/deeplearning/triton-inference-server/.../tutorials/Popular_Models_Guide/StableDiffusion/`
- **Brev**：`developer.nvidia.com/brev`
- **Retail Blueprint**：`nvidianews.nvidia.com/news/nvidia-announces-blueprint-for-ai-retail-shopping-assistants`、`github.com/NVIDIA-AI-Blueprints/retail-shopping-assistant`
- **CATCHES / RealFit**：Business Wire `20260316837622`（+ Business of Fashion 獨立佐證）
- **Supabase Edge AI**：`supabase.com/blog/ai-inference-now-available-in-supabase-edge-functions`、`supabase.com/docs/guides/functions/ai-models`
