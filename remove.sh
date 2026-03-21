#!/bin/bash
# SentiCore Uninstaller for OpenClaw
# Usage: bash remove.sh [--agent AGENT_NAME]

set -e

AGENT_FILTER=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --agent)
      AGENT_FILTER="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: bash remove.sh [--agent AGENT_NAME]"
      exit 1
      ;;
  esac
done

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
  read -rp "Remove from which agent? " CHOICE

  if [[ "$CHOICE" == "a" || "$CHOICE" == "A" ]]; then
    TARGET=("${ALL_WORKSPACES[@]}")
  elif [[ "$CHOICE" =~ ^[0-9]+$ ]] && (( CHOICE >= 1 && CHOICE <= ${#ALL_WORKSPACES[@]} )); then
    TARGET=("${ALL_WORKSPACES[$((CHOICE-1))]}")
  else
    echo "Invalid selection."
    exit 1
  fi
fi

# Remove function
remove_from() {
  local WORKSPACE="$1"
  local SKILLS_DIR="$WORKSPACE/skills"
  local TOOLS_FILE="$WORKSPACE/TOOLS.md"
  local AGENT_NAME
  AGENT_NAME=$(basename "$(dirname "$WORKSPACE")" | sed 's/^\.openclaw-//')

  echo "▶ $AGENT_NAME"

  # Remove skill files (both languages)
  local REMOVED=0
  for SKILL in "$SKILLS_DIR"/emotion_skill_*.md; do
    if [[ -f "$SKILL" ]]; then
      rm "$SKILL"
      echo "  ✓ Removed $(basename "$SKILL")"
      REMOVED=1
    fi
  done
  if [[ $REMOVED -eq 0 ]]; then
    echo "  ✓ No skill files found, skipped"
  fi

  # Remove SentiCore block from TOOLS.md
  if [[ -f "$TOOLS_FILE" ]]; then
    if grep -q "SentiCore Installed" "$TOOLS_FILE"; then
      ORIG_LINES=$(grep -o 'lines=[0-9]*' "$TOOLS_FILE" | grep -o '[0-9]*')
      head -n "$ORIG_LINES" "$TOOLS_FILE" > /tmp/senticore_tools_tmp && mv /tmp/senticore_tools_tmp "$TOOLS_FILE"
      echo "  ✓ Removed from TOOLS.md"
    else
      echo "  ✓ SentiCore not found in TOOLS.md, skipped"
    fi
  else
    echo "  ⚠ TOOLS.md not found, skipped"
  fi

  echo ""
}

echo "Removing SentiCore..."
echo ""

for WORKSPACE in "${TARGET[@]}"; do
  remove_from "$WORKSPACE"
done

echo "Done. SentiCore has been removed."
