# Hermes Agent + SentiCore：打造有情感的 AI 代理人

> 讓你的 AI 不只會回答問題，還會「感受」。

本指南教你如何在 [Hermes Agent](https://github.com/NousResearch/hermes-agent) 上安裝 [SentiCore](https://github.com/chuchuyei/SentiCore) 情緒引擎，讓你的代理人擁有 30 維動態情緒、時間衰減、性格演化。

---

## 前置需求

- macOS / Linux / WSL2
- git
- 一個 LLM API key（OpenRouter / Anthropic / MiniMax / 任何 OpenAI-compatible）

---

## Step 1：安裝 Hermes Agent

```bash
curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash
source ~/.bashrc  # 或 source ~/.zshrc
```

驗證安裝：
```bash
hermes --version
```

---

## Step 2：設定 Hermes

```bash
hermes setup
```

互動式設定，選擇你的 LLM provider 和模型。或手動設定：

```bash
hermes model          # 選擇模型
hermes config set model.provider anthropic  # 或 minimax / openrouter
```

在 `~/.hermes/.env` 中設定 API key：
```env
# 選一個即可
ANTHROPIC_API_KEY=your-key
# 或
MINIMAX_API_KEY=your-key
# 或
OPENROUTER_API_KEY=your-key
```

---

## Step 3：建立你的代理人 Profile

```bash
hermes profile create my-agent
```

這會建立 `~/.hermes/profiles/my-agent/`，包含獨立的設定和記憶。

---

## Step 4：安裝 SentiCore

```bash
git clone https://github.com/chuchuyei/SentiCore.git
cd SentiCore
```

### 4a. 建立 SOUL.md

SentiCore 需要一個 `soul.md` 來定義代理人的人格基線。你可以用範本：

```bash
cp templates/sample_soul.md ~/.hermes/profiles/my-agent/soul_base.md
```

編輯 `soul_base.md`，定義你的代理人個性：
- 名字、性別、說話風格
- 基本情緒基線（哪些情緒偏高/偏低）
- 與使用者的關係

### 4b. 合併到 SOUL.md

Hermes 的 `SOUL.md` 就是 system prompt。把三個檔案合併：

```bash
cat orchestration_prompt_zh.md > ~/.hermes/profiles/my-agent/SOUL.md
echo "" >> ~/.hermes/profiles/my-agent/SOUL.md
cat ~/.hermes/profiles/my-agent/soul_base.md >> ~/.hermes/profiles/my-agent/SOUL.md
echo "" >> ~/.hermes/profiles/my-agent/SOUL.md
cat emotion_skill_zh.md >> ~/.hermes/profiles/my-agent/SOUL.md
```

> 英文版用 `orchestration_prompt_en.md` 和 `emotion_skill_en.md`。

### 4c. 設定情緒狀態持久化

建立情緒狀態檔案：

```bash
mkdir -p ~/.hermes/profiles/my-agent/memory
```

在 SOUL.md 的情緒引擎段落中，將 `emotion_state.json` 路徑指向：
```
~/.hermes/profiles/my-agent/memory/emotion_state.json
```

代理人首次啟動時會根據 soul.md 自動初始化情緒基線。

---

## Step 5：啟動代理人

### CLI 模式（互動對話）

```bash
hermes --profile my-agent
# 或用 alias
my-agent chat
```

### Telegram 模式

在 `.env` 中加入：
```env
TELEGRAM_BOT_TOKEN=your-bot-token
TELEGRAM_ALLOWED_USERS=your-telegram-user-id
```

啟動 gateway：
```bash
my-agent gateway start
```

---

## Step 6：驗證 SentiCore 運作

跟你的代理人聊天，第一次回覆結尾應該會輸出情緒 JSON：

```json
{
  "timestamp": "2026-04-09T10:00:00+08:00",
  "trigger_event": "Baseline initialized from soul.md",
  "emotions": {
    "Joy": 60, "Contentment": 45, "Calm": 40, ...
  }
}
```

測試情緒變化：
1. 說一些開心的話 → Joy / Amusement 應該上升
2. 等幾小時再聊 → 情緒應該衰減回基線（λ=0.05，半衰期約 14 小時）
3. 持續互動 → Baseline Drift 會讓性格緩慢演化（每次 0.1%）

---

## 進階：搭配 Honcho 實現跨 Session 記憶

SentiCore 讓代理人有情感，[Honcho](https://github.com/plastic-labs/honcho) 讓代理人有記憶。兩者搭配：

```bash
# 安裝 Honcho（自架）
git clone https://github.com/plastic-labs/honcho.git
cd honcho
cp docker-compose.yml.example docker-compose.yml
docker compose up -d

# 設定 Hermes 連接 Honcho
cat > ~/.hermes/profiles/my-agent/honcho.json << 'EOF'
{
  "baseUrl": "http://127.0.0.1:8000",
  "enabled": true,
  "workspace": "my-workspace",
  "peerName": "user",
  "hosts": {
    "hermes.my-agent": {
      "enabled": true,
      "aiPeer": "my-agent",
      "recallMode": "hybrid",
      "saveMessages": true
    }
  }
}
EOF
```

這樣你的代理人不只有情感，還能跨對話記住你。

---

## 架構總覽

```
Hermes Agent
├── SOUL.md (System Prompt)
│   ├── SentiCore Orchestration（情緒運算邏輯）
│   ├── Agent Identity（人格定義）
│   └── Emotion Skill（30 維情緒矩陣）
│
├── memory/
│   └── emotion_state.json（情緒持久化）
│
├── Honcho（選配）
│   └── 跨 Session 對話記憶 + User Modeling
│
└── Gateway
    ├── Telegram
    ├── Discord
    └── CLI
```

---

## 常見問題

**Q: SentiCore 會用很多 token 嗎？**
A: SOUL.md 增加約 3-4K tokens，對 200K context window 的模型影響很小。

**Q: 可以用免費模型嗎？**
A: 可以。MiniMax M2.7 完全免費，效果不錯。OpenRouter 也有免費額度的模型。

**Q: 情緒會不會「壞掉」？**
A: SentiCore 有內建保護機制：情緒值限制在 0-100，衰減會自動拉回基線，Baseline Drift 每次只動 0.1%。

**Q: 可以裝在其他 Agent 框架嗎？**
A: 可以。SentiCore 是 prompt-based 的，任何支援 system prompt 的框架都能用。Hermes 只是其中一個選擇。

---

## 相關連結

- [Hermes Agent](https://github.com/NousResearch/hermes-agent) — 自我學習的 AI 代理人框架
- [SentiCore](https://github.com/chuchuyei/SentiCore) — 30 維動態情緒引擎
- [Honcho](https://github.com/plastic-labs/honcho) — AI 記憶與用戶建模

---

*Built with ❤️ by [chuchuyei](https://github.com/chuchuyei)*
