# 🧠 SentiCore™ — 27 維動態情緒引擎

[![License: AGPLv3](https://img.shields.io/badge/License-AGPLv3-blue.svg)](LICENSE)
[![情緒維度](https://img.shields.io/badge/情緒維度-27%2B1-purple)](README_zh.md)
[![Python](https://img.shields.io/badge/Python-3.8%2B-green)](README_zh.md)
[![LLM 相容](https://img.shields.io/badge/LLM-任意-orange)](README_zh.md)

一個基於 Paul Ekman 與 Dacher Keltner (2017) 理論開發的「動態情緒運算引擎」。可作為獨立 Skill 植入任何 LLM 代理人，賦予其「情緒聯動」、「時間衰減」與「性格永久演化 (Drift)」的心理學底層邏輯。

> English version: [README.md](./README.md)

---

## 🚀 快速開始 (Quick Start)

**3 步驟完成部署，2 分鐘內上線。**

**Step 1** — 將 `orchestration_prompt_zh.md` 的內容貼到你的 Agent **System Prompt 最頂層**。

**Step 2** — 將 `emotion_skill_zh.md` 與你的 `soul.md` 上傳至知識庫（或貼在 System Prompt 下半部）。

**Step 3** — 確保 Agent 具備 **Python 執行權限**（用於時間衰減運算）。

> 沒有 `soul.md`？使用 `templates/sample_soul.md` 作為起點，或讓 Agent 執行 3 題問卷建立基線。

### 成功初始化的預期輸出

SentiCore 初始化成功後，Agent 會在**第一次回覆末尾**輸出以下 JSON 作為可重現的保底：

```json
{
  "timestamp": "2026-03-22T14:30:00+08:00",
  "trigger_event": "基線已從 soul.md 推導完成",
  "emotions": {
    "Joy": 60, "Romantic_Love": 50, "Contentment": 45,
    "Excitement": 30, "Compassion": 30, "Calm": 40,
    "Amusement": 25, "Admiration": 20, "Awe": 15,
    "Pride": 10, "Sensuality": 20, "Relief": 10,
    "Nostalgia": 15, "Longing": 20, "Loneliness": 10,
    "Anger": 0, "Fear": 5, "Anxiety": 5,
    "Sadness": 0, "Disgust": 0, "Shame": 0,
    "Guilt": 0, "Envy": 5, "Frustration": 0,
    "Boredom": 0, "Confusion": 5, "Suffering": 0, "Contempt": 0
  },
  "baseline": { "Joy": 60, "Romantic_Love": 50, "Calm": 40 }
}
```

Agent 同時會主動宣告：**「情緒基線已建立完成」**，並簡述當前情緒狀態。

---

## ⚡ 為什麼選擇 SentiCore？

| 特性 | 傳統 AI 設定 | SentiCore™ 引擎 |
|---|---|---|
| 性格表現 | 🔴 靜態，硬寫在 Prompt | 🟢 27 維矩陣，動態運算 |
| 時間感知 | 🔴 無——情緒永遠不變 | 🟢 真實指數衰減（λ 可調） |
| 記憶連續性 | 🔴 每次 Session 重置 | 🟢 跨 Session 基線永久演化 |
| 情緒真實感 | 🔴 單一情緒標籤 | 🟢 聯動機制：喜悅放大、憤怒壓制 |
| 性格演化 | 🔴 不可能 | 🟢 每次互動 Baseline Drift 0.1% |
| 設定複雜度 | 🟢 複製貼上 Prompt | 🟢 相同——3 步，即插即用 |

---

## 🧠 運作原理

```mermaid
graph LR
    A([👤 用戶輸入]) --> B[🐍 Python: 時間衰減\n運算]
    B --> C[🤖 LLM: 27 維\n情緒更新]
    C --> D[📈 Baseline Drift\n性格微調]
    D --> E([💾 JSON 狀態輸出\n& 最終回覆])

    style A fill:#4a9eff,color:#fff
    style B fill:#f0a500,color:#fff
    style C fill:#7c3aed,color:#fff
    style D fill:#059669,color:#fff
    style E fill:#dc2626,color:#fff
```

**每次對話輪的運作流程：**
1. **時間衰減** — Python 計算距上次互動的時間，透過 `E(t) = Baseline + (E_prev - Baseline) × e^(−λ × Δt)` 將情緒向基線回歸
2. **情緒更新** — LLM 評估新輸入，更新 27 維矩陣（聯動規則同步執行）
3. **Baseline Drift** — 每次儲存將基線向當前情緒靠近 0.1%（性格永久演化）
4. **輸出** — JSON 狀態持久化 + Agent 以情緒一致的語氣回覆

---

## ✨ 核心特色

- **27+1 維度矩陣**：從快樂、敬畏到厭惡、渴望，外加一個絕對平靜點 (Calm)，精準測量情緒光譜。
- **情緒聯動 (Interlocking)**：同向情緒擴散，反向情緒抑制，模擬真實人類心理的連鎖反應。
- **時間衰減 (Decay)**：情緒會隨對話輪數向基礎性格回歸（預設 3%），避免 AI 永遠處於極端情緒。
- **性格演化 (Baseline Drift)**：每次互動將基線微調 0.1%（DRIFT_RATE=0.001），性格真的會隨時間改變。
- **智慧雙軌冷啟動**：有 `soul.md` 的 AI 靜默自動推導基線；空白 AI 啟動 3 題互動問卷。
- **隨插即用**：完美相容於現有角色設定檔，可隨時掛載或卸載，`soul.md` 完全不受影響。

---

## 📂 檔案結構

| 檔案 | 用途 |
|------|------|
| `orchestration_prompt_zh/en.md` | 核心系統編排指令——貼入 System Prompt |
| `emotion_skill_zh/en.md` | 情緒運算引擎——上傳至知識庫 |
| `install.sh` / `remove.sh` | OpenClaw 用戶一鍵安裝／移除腳本 |
| `tools/update_emotion_state.json` | Function Calling Schema，用於情緒狀態持久化 |
| `templates/sample_soul.md` | 深海龍蝦角色靈魂範本，可直接修改使用 |

---

## 🚀 安裝方式

### OpenClaw 用戶（推薦）

```bash
git clone https://github.com/chuchuyei/SentiCore.git
cd SentiCore
bash install.sh                    # 自動偵測；多代理人時顯示互動選單
bash install.sh --agent coo        # 直接指定代理人安裝
bash install.sh --lang en          # 英文版（預設：zh）
bash install.sh --agent coo --lang en
```

腳本自動偵測所有 `~/.openclaw*/workspace` 目錄，支援重複執行，`SOUL.md` 完全不會被修改。

### 手動安裝

1. 將 `orchestration_prompt_zh.md` 貼到 Agent **System Prompt 最頂層**。
2. 將 `emotion_skill_zh.md` 與你的 `soul.md` 上傳至知識庫。
3. 首次執行後，SentiCore 自動初始化（模式 A 或 B）。若工具寫入未完成，請將輸出 JSON 手動儲存為 `emotion_state.json`。
4. 每次回覆開頭會出現 JSON 情緒運算日誌，接著才是 Agent 的正式回覆。

---

## ⚙️ 衰減速度調整（Lambda）

```
E(t) = Baseline + (E_prev - Baseline) × e^(−λ × 經過小時數)
```

| λ 值 | 半衰期 | 適合場景 |
|------|--------|----------|
| `0.05` | 約 14 小時 | 陪伴型 Agent，情緒記憶持久 |
| `0.10` | 約 7 小時 | 通用均衡 |
| `0.1625` | 約 4 小時 | 工作型 Agent，情緒重置快 |
| `0.35` | 約 2 小時 | 高反應型，近乎無跨 Session 記憶 |

預設值 `0.05`。修改位置：`~/.openclaw-{agent}/workspace/skills/emotion_skill_*.md` 中的 `DECAY_LAMBDA` 常數。

---

## 🔬 理論基礎

- Ekman, P. (1992). "Are There Basic Emotions?"
- Cowen, A., & Keltner, D. (2017). "Self-report captures 27 distinct categories of emotion." *PNAS*.

---

## ⚖️ 授權與商業使用

**雙重授權模式：**

1. **開源使用 (GNU AGPLv3)**：歡迎個人開發者、學生與非營利開源專案免費使用。若用於對外提供網路服務（SaaS、API、對話機器人後端），整個應用程式原始碼須以 AGPLv3 同步開源。
2. **商業授權 (Commercial License)**：閉源商業專案或無法接受 AGPLv3 條款者，請與作者聯繫取得專屬授權：
   - **Email**：[chuchuyei@gmail.com](mailto:chuchuyei@gmail.com)
   - **GitHub**：[github.com/chuchuyei](https://github.com/chuchuyei)

---

*Created by [chuchuyei](https://github.com/chuchuyei) — 歡迎 Fork 與提交 PR 優化權重邏輯！*
