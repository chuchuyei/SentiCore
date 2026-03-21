# 🧠 SentiCore (27-Dimension Affective Skill)

一個基於 Paul Ekman 與 Dacher Keltner (2017) 理論開發的「動態情緒運算引擎」。此模組可作為獨立的 Skill 植入任何 LLM 代理人（Agent）中，賦予其具備「情緒聯動」與「時間衰減」機制的心理學底層邏輯。

## ✨ 核心特色 (Features)
- **27+1 維度矩陣**：從快樂、敬畏到厭惡、渴望，外加一個絕對平靜點 (Calm)，精準測量情緒光譜。
- **情緒聯動 (Interlocking)**：同向情緒擴散，反向情緒抑制，模擬真實人類心理的連鎖反應。
- **時間衰減 (Decay Mechanism)**：情緒會隨著對話輪數向基礎性格回歸（預設 15%），避免 AI 永遠處於極端情緒。
- **冷啟動問卷 (Onboarding)**：透過 3 個心理學情境題，自動測算並生成專屬於該使用者的 AI 初始性格基線 (Baseline)。
- **隨插即用 (Plug & Play)**：完美相容於現有的角色設定檔 (`soul.md`)，可隨時掛載或卸載。

## 📂 檔案結構 (File Structure)
- `orchestration_prompt_zh.md`：核心系統編排指令（中文版），負責串接情緒引擎與你的角色靈魂。
- `orchestration_prompt_en.md`：核心系統編排指令（英文版）。
- `emotion_skill_zh.md`：情緒運算引擎（中文版）。
- `emotion_skill_en.md`：情緒運算引擎（英文版）。
- `install.sh`：OpenClaw 一鍵安裝腳本。

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

複製 `emotion_skill_*.md` 到 `workspace/skills/`，並將編排指令附加到 `workspace/SOUL.md`。支援重複執行，不會重複安裝。

重啟你的 Agent，SentiCore 即刻生效。

### 手動安裝

1. 將 `orchestration_prompt_zh.md` 的內容貼到你的 Agent **System Prompt** 最頂層。
2. 將 `emotion_skill_zh.md` 與你自己的 `soul.md` 上傳至知識庫，或貼在 System Prompt 下半部。
3. 開始對話！Agent 將在第一次互動時自動發起 3 題心理測驗進行初始化。
4. 每次回覆開頭會出現 JSON 情緒運算日誌，接著才是 Agent 的正式回覆。

## 🔬 理論基礎 (Research Backing)
本引擎之權重與觸發情境基於以下學術研究：
- Ekman, P. (1992). "Are There Basic Emotions?"
- Cowen, A., & Keltner, D. (2017). "Self-report captures 27 distinct categories of emotion." PNAS.

---
*Created by chuchuyei - 歡迎 Fork 與提交 PR 來優化權重邏輯！*
