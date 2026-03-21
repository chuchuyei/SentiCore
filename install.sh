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
ORCHESTRATION_FILE="$SCRIPT_DIR/orchestration_prompt_${LANG_CODE}.md"
SENTINEL="<!-- SentiCore Installed -->"

# Check source files
if [[ ! -f "$SKILL_FILE" ]]; then
  echo "Error: $SKILL_FILE not found"
  exit 1
fi
if [[ ! -f "$ORCHESTRATION_FILE" ]]; then
  echo "Error: $ORCHESTRATION_FILE not found"
  exit 1
fi

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
  # --agent specified: find matching workspace
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
  # Only one agent: install directly
  TARGET=("${ALL_WORKSPACES[@]}")

else
  # Multiple agents: show interactive menu
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
  local SOUL_FILE="$WORKSPACE/SOUL.md"
  local AGENT_NAME
  AGENT_NAME=$(basename "$(dirname "$WORKSPACE")" | sed 's/^\.openclaw-//')

  echo "▶ $AGENT_NAME"

  if [[ -d "$SKILLS_DIR" ]]; then
    cp "$SKILL_FILE" "$SKILLS_DIR/emotion_skill_${LANG_CODE}.md"
    echo "  ✓ emotion_skill_${LANG_CODE}.md → skills/"
  else
    echo "  ⚠ skills/ not found, skipping skill file"
  fi

  if [[ -f "$SOUL_FILE" ]]; then
    if grep -qF "SentiCore Installed" "$SOUL_FILE"; then
      echo "  ✓ orchestration prompt already installed, skipped"
    else
      ORIG_LINES=$(wc -l < "$SOUL_FILE" | tr -d ' ')
      printf "\n\n<!-- SentiCore Installed | lines=%s -->\n" "$ORIG_LINES" >> "$SOUL_FILE"
      cat "$ORCHESTRATION_FILE" >> "$SOUL_FILE"
      echo "  ✓ orchestration prompt → SOUL.md"
    fi
  else
    echo "  ⚠ SOUL.md not found, skipping orchestration prompt"
  fi

  echo ""
}

echo "Installing SentiCore [lang=${LANG_CODE}]..."
echo ""

for WORKSPACE in "${TARGET[@]}"; do
  install_to "$WORKSPACE"
done

echo "Done. SentiCore is ready."
