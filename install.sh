#!/bin/bash
# SentiCore Installer for OpenClaw
# Usage: bash install.sh [--lang en]

set -e

LANG_CODE="zh"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --lang)
      LANG_CODE="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: bash install.sh [--lang en|zh]"
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

# Detect OpenClaw workspaces
WORKSPACES=($(find "$HOME" -maxdepth 2 -name "workspace" -path "*/.openclaw*/workspace" -type d 2>/dev/null))

if [[ ${#WORKSPACES[@]} -eq 0 ]]; then
  echo "Error: No OpenClaw workspace found under $HOME"
  exit 1
fi

echo "Found ${#WORKSPACES[@]} OpenClaw workspace(s). Installing SentiCore [lang=${LANG_CODE}]..."
echo ""

for WORKSPACE in "${WORKSPACES[@]}"; do
  SKILLS_DIR="$WORKSPACE/skills"
  SOUL_FILE="$WORKSPACE/SOUL.md"
  AGENT_NAME=$(basename "$(dirname "$WORKSPACE")")

  echo "▶ $AGENT_NAME"

  # Install skill file
  if [[ -d "$SKILLS_DIR" ]]; then
    cp "$SKILL_FILE" "$SKILLS_DIR/emotion_skill_${LANG_CODE}.md"
    echo "  ✓ emotion_skill_${LANG_CODE}.md → skills/"
  else
    echo "  ⚠ skills/ not found, skipping skill file"
  fi

  # Append orchestration prompt to SOUL.md (idempotent)
  if [[ -f "$SOUL_FILE" ]]; then
    if grep -qF "$SENTINEL" "$SOUL_FILE"; then
      echo "  ✓ orchestration prompt already installed, skipped"
    else
      printf "\n\n%s\n" "$SENTINEL" >> "$SOUL_FILE"
      cat "$ORCHESTRATION_FILE" >> "$SOUL_FILE"
      echo "  ✓ orchestration prompt → SOUL.md"
    fi
  else
    echo "  ⚠ SOUL.md not found, skipping orchestration prompt"
  fi

  echo ""
done

echo "Done. SentiCore is ready."
