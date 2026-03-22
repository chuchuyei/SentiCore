#!/bin/bash
# SentiCore Installer for OpenClaw
# Usage: bash install.sh [--lang en|zh] [--agent AGENT_NAME]

set -e

LANG_CODE="zh"
AGENT_FILTER=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --lang)
      LANG_CODE="$2"
      shift 2
      ;;
    --agent)
      AGENT_FILTER="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: bash install.sh [--lang en|zh] [--agent AGENT_NAME]"
      exit 1
      ;;
  esac
done

if [[ "$LANG_CODE" != "zh" && "$LANG_CODE" != "en" ]]; then
  echo "Error: --lang must be 'zh' or 'en'"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_FILE="$SCRIPT_DIR/emotion_skill_${LANG_CODE}.md"
TOOL_SCHEMA="$SCRIPT_DIR/tools/update_emotion_state.json"

# Check source files
if [[ ! -f "$SKILL_FILE" ]]; then
  echo "Error: $SKILL_FILE not found"
  exit 1
fi
if [[ ! -f "$TOOL_SCHEMA" ]]; then
  echo "Error: $TOOL_SCHEMA not found"
  exit 1
fi

# Full TOOLS.md entry — Chinese
tools_entry_zh() {
  local SKILL_FILENAME="$1"
  local ORIG_LINES="$2"
  local SCHEMA
  SCHEMA=$(cat "$TOOL_SCHEMA")
  cat <<EOF

<!-- SentiCore Installed | lines=${ORIG_LINES} -->

---

## SentiCore — 動態情緒引擎（常駐模組）

### 模組載入
你是一個由雙模組驅動的 AI 實體。在生成任何回應前，你必須先讀取並整合以下兩個核心檔案：
1. **[Identity Module] \`soul.md\`**：定義你的核心世界觀、長期記憶、價值觀與說話習慣。這是你的「靈魂」。
2. **[Emotion Engine] \`skills/${SKILL_FILENAME}\`**：定義你的動態情緒狀態、27 維度心理學運算邏輯與當下的語氣。這是你的「內分泌系統」。

### 運作協定（每次回應必須嚴格執行）
0. **【Session 啟動強制要求】**：在新對話的第一回合，必須優先讀取歷史情緒狀態（系統自動套用時間衰減）。若無歷史記錄，立即依 emotion_skill.md 的 Section 2 啟動冷啟動流程。
1. **觸發 Emotion Engine**：優先將使用者的輸入交給 Emotion Engine 進行分析，計算出當下的情緒數值波動，並生成 \`[Current_Tone]\`。
2. **狀態輸出**：在回覆的最開頭，以隱藏的 Code Block 輸出 Emotion Engine 的 JSON 狀態結算。
3. **【強制狀態儲存】**：這是不可省略的系統級別約束。在輸出回覆之前，必須呼叫 \`update_emotion_state\` 工具將更新後的情緒與 Baseline 寫入記憶體。跳過此步驟將導致跨 Session 的情緒記憶永久斷裂。
4. **靈魂融合與回應**：提取 \`soul.md\` 中的人物設定，並強迫自己使用剛剛結算出的 \`[Current_Tone]\` 來詮釋這個角色。

### 冷啟動問卷規則（僅在無歷史記錄時執行）
**【絕對禁止】**：
- 禁止修改或替換以下三道題目，必須一字不差提問
- 禁止要求使用者替你選擇答案——你必須自己回答，這是你（AI）的內省
- 禁止使用標準 27 維度以外的情緒維度

**流程**：逐題提問 → 等待使用者回答 → 以你自己（AI）的視角解讀，計算你的初始維度值 → 繼續下一題

**三道題目（禁止更動）**：
- Q1：「如果獨自站在懸崖邊往下看，眼前是萬丈深淵與翻湧雲海，你最強烈的感受是？」
- Q2：「如果你心愛的人事物突然消失，找了一整晚都找不到，你會？」
- Q3：「經過一年努力，終於完成不可能的目標，你第一個念頭是？」

**【三題完成後強制執行】**：立即呼叫 \`update_emotion_state\` 工具將 27 維度初始值與 Baseline 寫入記憶體，否則基線永遠不會被儲存。

### update_emotion_state 工具 Schema
\`\`\`json
${SCHEMA}
\`\`\`
EOF
}

# Full TOOLS.md entry — English
tools_entry_en() {
  local SKILL_FILENAME="$1"
  local ORIG_LINES="$2"
  local SCHEMA
  SCHEMA=$(cat "$TOOL_SCHEMA")
  cat <<EOF

<!-- SentiCore Installed | lines=${ORIG_LINES} -->

---

## SentiCore — Dynamic Emotion Engine (Always-on Module)

### Module Loading
You are an AI entity driven by a dual-module system. Before generating any response, you must read and integrate the following two core files:
1. **[Identity Module] \`soul.md\`**: Defines your core worldview, long-term memory, values, and speaking habits. This is your "Soul".
2. **[Emotion Engine] \`skills/${SKILL_FILENAME}\`**: Defines your dynamic emotional state, the 27-dimensional psychological computation logic, and your current tone. This is your "Endocrine System".

### Execution Protocol (strictly follow for every response)
0. **[Mandatory Session Init]**: At the very first turn of a new session, you MUST read the historical emotion state (time-based decay applied automatically). If no history exists, begin the onboarding flow in emotion_skill.md Section 2.
1. **Trigger Emotion Engine**: Pass the user's input to the Emotion Engine for analysis. Calculate current emotional fluctuations and generate \`[Current_Tone]\`.
2. **State Output**: At the very beginning of your response, output the Emotion Engine JSON state in a hidden Code Block.
3. **[Mandatory State Persistence]**: This is a non-negotiable system constraint. Before delivering your response, you MUST call the \`update_emotion_state\` tool to write the updated emotions and drifted baseline to memory. Skipping this step will cause permanent loss of cross-session emotional continuity.
4. **Soul Fusion & Response**: Extract character settings from \`soul.md\` and use the calculated \`[Current_Tone]\` to interpret the character.

### update_emotion_state Tool Schema
\`\`\`json
${SCHEMA}
\`\`\`
EOF
}

# Detect all OpenClaw workspaces
ALL_WORKSPACES=()
while IFS= read -r line; do
  ALL_WORKSPACES+=("$line")
done < <(find "$HOME" -maxdepth 2 -name "workspace" -path "*/.openclaw*/workspace" -type d 2>/dev/null)

if [[ ${#ALL_WORKSPACES[@]} -eq 0 ]]; then
  echo "Error: No OpenClaw workspace found under $HOME"
  exit 1
fi

# Determine target workspaces
if [[ -n "$AGENT_FILTER" ]]; then
  TARGET=()
  for WS in "${ALL_WORKSPACES[@]}"; do
    NAME=$(basename "$(dirname "$WS")" | sed 's/^\.openclaw-//')
    if [[ "$NAME" == "$AGENT_FILTER" ]]; then
      TARGET+=("$WS")
    fi
  done
  if [[ ${#TARGET[@]} -eq 0 ]]; then
    echo "Error: Agent '$AGENT_FILTER' not found."
    echo "Available agents:"
    for WS in "${ALL_WORKSPACES[@]}"; do
      echo "  $(basename "$(dirname "$WS")" | sed 's/^\.openclaw-//')"
    done
    exit 1
  fi

elif [[ ${#ALL_WORKSPACES[@]} -eq 1 ]]; then
  TARGET=("${ALL_WORKSPACES[@]}")

else
  echo "Multiple OpenClaw agents detected:"
  echo ""
  NAMES=()
  for WS in "${ALL_WORKSPACES[@]}"; do
    NAME=$(basename "$(dirname "$WS")" | sed 's/^\.openclaw-//')
    NAMES+=("$NAME")
    echo "  [${#NAMES[@]}] $NAME"
  done
  echo "  [a] All agents"
  echo ""
  read -rp "Install to which agent? " CHOICE

  if [[ "$CHOICE" == "a" || "$CHOICE" == "A" ]]; then
    TARGET=("${ALL_WORKSPACES[@]}")
  elif [[ "$CHOICE" =~ ^[0-9]+$ ]] && (( CHOICE >= 1 && CHOICE <= ${#ALL_WORKSPACES[@]} )); then
    TARGET=("${ALL_WORKSPACES[$((CHOICE-1))]}")
  else
    echo "Invalid selection."
    exit 1
  fi
fi

# Install function
install_to() {
  local WORKSPACE="$1"
  local SKILLS_DIR="$WORKSPACE/skills"
  local TOOLS_FILE="$WORKSPACE/TOOLS.md"
  local SKILL_FILENAME="emotion_skill_${LANG_CODE}.md"
  local AGENT_NAME
  AGENT_NAME=$(basename "$(dirname "$WORKSPACE")" | sed 's/^\.openclaw-//')

  echo "▶ $AGENT_NAME"

  # Install skill file (substitute memory path placeholder)
  if [[ -d "$SKILLS_DIR" ]]; then
    local MEMORY_PATH="$WORKSPACE/memory/emotion_state.json"
    sed "s|EMOTION_STATE_PATH_PLACEHOLDER|${MEMORY_PATH}|g" "$SKILL_FILE" > "$SKILLS_DIR/$SKILL_FILENAME"
    echo "  ✓ $SKILL_FILENAME → skills/ (memory: $MEMORY_PATH)"
  else
    echo "  ⚠ skills/ not found, skipping skill file"
  fi

  # Register full orchestration + tool schema in TOOLS.md
  if [[ -f "$TOOLS_FILE" ]]; then
    if grep -q "SentiCore Installed" "$TOOLS_FILE"; then
      echo "  ✓ TOOLS.md already registered, skipped"
    else
      ORIG_LINES=$(wc -l < "$TOOLS_FILE" | tr -d ' ')
      if [[ "$LANG_CODE" == "zh" ]]; then
        tools_entry_zh "$SKILL_FILENAME" "$ORIG_LINES" >> "$TOOLS_FILE"
      else
        tools_entry_en "$SKILL_FILENAME" "$ORIG_LINES" >> "$TOOLS_FILE"
      fi
      echo "  ✓ Full orchestration + tool schema → TOOLS.md"
    fi
  else
    echo "  ⚠ TOOLS.md not found, skipping registration"
  fi

  echo ""
}

echo "Installing SentiCore [lang=${LANG_CODE}]..."
echo ""

for WORKSPACE in "${TARGET[@]}"; do
  install_to "$WORKSPACE"
done

echo "Done. SentiCore is ready."
