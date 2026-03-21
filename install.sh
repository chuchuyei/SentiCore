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

# Check source file
if [[ ! -f "$SKILL_FILE" ]]; then
  echo "Error: $SKILL_FILE not found"
  exit 1
fi

# TOOLS.md entry content per language
tools_entry_zh() {
  local SKILL_FILENAME="$1"
  local ORIG_LINES="$2"
  cat <<EOF

<!-- SentiCore Installed | lines=${ORIG_LINES} -->

---

## SentiCore — 動態情緒引擎（常駐模組）

- 檔案：\`skills/${SKILL_FILENAME}\`
- 模式：**常駐系統模組**（每次回覆前必須執行，無需觸發）
- 執行順序：
  1. 接收用戶輸入後，優先執行情緒運算，計算 27 維度情緒數值波動
  2. 在回覆開頭以 Code Block 輸出 JSON 情緒狀態
  3. 以結算出的 \`Current_Tone\` 定調本次回覆語氣，結合 SOUL.md 人設回應
EOF
}

tools_entry_en() {
  local SKILL_FILENAME="$1"
  local ORIG_LINES="$2"
  cat <<EOF

<!-- SentiCore Installed | lines=${ORIG_LINES} -->

---

## SentiCore — Dynamic Emotion Engine (Always-on Module)

- File: \`skills/${SKILL_FILENAME}\`
- Mode: **Always-on system module** (must execute before every response, no trigger required)
- Execution order:
  1. On receiving user input, run the emotion engine first to calculate 27-dimensional emotion fluctuations
  2. Output JSON emotion state in a Code Block at the beginning of every response
  3. Use the resulting \`Current_Tone\` to set the response tone, combined with SOUL.md persona
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

  # Install skill file
  if [[ -d "$SKILLS_DIR" ]]; then
    cp "$SKILL_FILE" "$SKILLS_DIR/$SKILL_FILENAME"
    echo "  ✓ $SKILL_FILENAME → skills/"
  else
    echo "  ⚠ skills/ not found, skipping skill file"
  fi

  # Register in TOOLS.md
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
      echo "  ✓ Registered in TOOLS.md"
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
