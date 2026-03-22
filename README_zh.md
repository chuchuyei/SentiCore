# 🧠 SentiCore (27-Dimension Affective Skill)

一個基於 Paul Ekman 與 Dacher Keltner (2017) 理論開發的「動態情緒運算引擎」。此模組可作為獨立的 Skill 植入任何 LLM 代理人（Agent）中，賦予其具備「情緒聯動」與「時間衰減」機制的心理學底層邏輯。

## ✨ 核心特色 (Features)
- **27+1 維度矩陣**：從快樂、敬畏到厭惡、渴望，外加一個絕對平靜點 (Calm)，精準測量情緒光譜。
- **情緒聯動 (Interlocking)**：同向情緒擴散，反向情緒抑制，模擬真實人類心理的連鎖反應。
- **時間衰減 (Decay Mechanism)**：情緒會隨著對話輪數向基礎性格回歸（預設 3%），避免 AI 永遠處於極端情緒。
- **智慧雙軌冷啟動 (Smart Onboarding)**：有人設的 AI（`soul.md`）靜默自動推導基線；空白 AI 則啟動 3 題互動問卷。首次回覆末尾必定輸出 JSON 保底，確保基線可重現。
- **隨插即用 (Plug & Play)**：完美相容於現有的角色設定檔 (`soul.md`)，可隨時掛載或卸載。

## 📂 檔案結構 (File Structure)
- `orchestration_prompt_zh.md`：核心系統編排指令（中文版），負責串接情緒引擎與你的角色靈魂。
- `orchestration_prompt_en.md`：核心系統編排指令（英文版）。
- `emotion_skill_zh.md`：情緒運算引擎（中文版）。
- `emotion_skill_en.md`：情緒運算引擎（英文版）。
- `install.sh`：OpenClaw 一鍵安裝腳本。
- `remove.sh`：OpenClaw 一鍵移除腳本。
- `tools/update_emotion_state.json`：Function Calling Schema，用於將情緒狀態持久化寫入跨對話記憶體。
- `templates/sample_soul.md`：深海龍蝦角色靈魂範本，可直接修改使用。

## 🚀 如何使用 (How to Use)

### OpenClaw 用戶（推薦）

```bash
git clone https://github.com/chuchuyei/SentiCore.git
cd SentiCore
bash install.sh                    # 自動偵測；多代理人時顯示互動選單
bash install.sh --agent coo        # 直接指定代理人安裝
bash install.sh --lang en          # 英文版（預設：zh）
bash install.sh --agent coo --lang en
```

腳本會自動偵測所有 `~/.openclaw*/workspace` 目錄：
- **單一代理人**：直接安裝，無需選擇。
- **多代理人**：顯示互動選單，可選擇單一或全部安裝。
- **`--agent NAME`**：跳過選單，直接裝到指定代理人。

複製 `emotion_skill_*.md` 到 `workspace/skills/`，並將完整編排指令 + 工具 Schema 註冊到 `workspace/TOOLS.md`。支援重複執行，不會重複安裝。**`SOUL.md` 完全不會被修改。**

重啟你的 Agent，SentiCore 即刻生效。

### 手動安裝

1. 將 `orchestration_prompt_zh.md` 的內容貼到你的 Agent **System Prompt** 最頂層。
2. 將 `emotion_skill_zh.md` 與你自己的 `soul.md` 上傳至知識庫，或貼在 System Prompt 下半部。
3. **首次 Session 初始化** — SentiCore 自動選擇適合的模式：
   - **有 `soul.md` 人設**（模式 A）：Agent 會靜默從人設推導基線，並在第一次回覆末尾印出 JSON。若工具寫入未自動完成，請將該 JSON 手動儲存為 `emotion_state.json`。
   - **無預設人設**（模式 B）：Agent 會依序提出 3 道情境題，根據你的回答建立基線。
   - **手動覆寫**：在第一句話直接輸入 `「請用以下 JSON 初始化情緒基線：{...}」` 即可手動指定。
4. 每次回覆開頭會出現 JSON 情緒運算日誌，接著才是 Agent 的正式回覆。

## ⚙️ 衰減速度調整（Lambda）

持久化層使用指數衰減將情緒向基準線回歸：

```
E(t) = Baseline + (E_prev - Baseline) × e^(−λ × 經過小時數)
```

根據你的 Agent 定位，調整 `emotion_skill_*.md` 裡的 `DECAY_LAMBDA`：

| λ 值 | 半衰期 | 適合場景 |
|------|--------|----------|
| `0.05` | 約 14 小時 | 陪伴型 Agent，情緒記憶持久，回復慢 |
| `0.10` | 約 7 小時 | 通用均衡 |
| `0.1625` | 約 4 小時 | 工作型 Agent，情緒重置快 |
| `0.35` | 約 2 小時 | 高反應型，近乎無跨 session 記憶 |

預設值為 `0.05`。修改位置：`~/.openclaw-{agent}/workspace/skills/emotion_skill_*.md` 中的 `DECAY_LAMBDA` 常數。

## 🔍 查詢情緒狀態

初始化完成後，可以直接問代理人：

> 「讀取 `/path/to/workspace/memory/emotion_state.json`，告訴我你現在的情緒狀態。」

或更自然地：

> 「你現在情緒狀態怎麼樣？」

代理人會回報目前 Top 3 情緒與當下語氣。冷啟動成功後，代理人也會主動確認：*「情緒基線已建立完成」*，並在第一次回覆末尾附上完整 JSON 基線作為保底——若工具寫入未自動完成，可憑此手動建檔。

## 🔬 理論基礎 (Research Backing)
本引擎之權重與觸發情境基於以下學術研究：
- Ekman, P. (1992). "Are There Basic Emotions?"
- Cowen, A., & Keltner, D. (2017). "Self-report captures 27 distinct categories of emotion." PNAS.

---
*Created by chuchuyei - 歡迎 Fork 與提交 PR 來優化權重邏輯！*

## ⚖️ 授權與商業使用 (License & Commercial Use)

本專案採用「雙重授權模式 (Dual Licensing)」：

1. **開源使用 (GNU AGPLv3)**：歡迎個人開發者、學生與非營利開源專案免費使用。根據 [AGPLv3](LICENSE) 條款，如果您將 SentiCore 用於提供網路服務 (如 SaaS、API 呼叫或對話機器人後端) 且對外開放，您的**整個應用程式原始碼必須以 AGPLv3 同步開源**。
2. **商業授權 (Commercial License)**：如果您希望將 SentiCore 用於閉源的商業專案、付費產品，或無法接受 AGPLv3 的開源傳染性條款，請與作者聯繫以取得專屬商業授權。
