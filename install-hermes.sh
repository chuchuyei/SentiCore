#!/bin/bash
# SentiCore Installer for Hermes Agent
# Usage: bash install-hermes.sh [--lang en|zh] [--profile PROFILE_NAME] [--dry-run]
#
# Installs SentiCore emotion engine into a Hermes Agent profile.
# If no profile is specified, installs to the default profile.

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()   { echo -e "${GREEN}[✓]${NC} $1"; }
info()  { echo -e "${BLUE}[→]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; }

LANG_CODE="zh"
PROFILE=""
DRY_RUN=false
HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --lang)
      LANG_CODE="$2"
      shift 2
      ;;
    --profile)
      PROFILE="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    -h|--help)
      echo "SentiCore Installer for Hermes Agent"
      echo ""
      echo "Usage: bash install-hermes.sh [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --lang en|zh       Language (default: zh)"
      echo "  --profile NAME     Hermes profile name (default: default profile)"
      echo "  --dry-run          Preview changes without modifying any files"
      echo "  -h, --help         Show this help"
      echo ""
      echo "Examples:"
      echo "  bash install-hermes.sh --dry-run                  # Preview installation"
      echo "  bash install-hermes.sh                            # Install to default profile (Chinese)"
      echo "  bash install-hermes.sh --lang en                  # Install in English"
      echo "  bash install-hermes.sh --profile my-agent         # Install to specific profile"
      echo "  bash install-hermes.sh --profile sec --lang zh    # Install to 'sec' profile in Chinese"
      exit 0
      ;;
    *)
      error "Unknown option: $1"
      echo "Usage: bash install-hermes.sh [--lang en|zh] [--profile PROFILE_NAME] [--dry-run]"
      exit 1
      ;;
  esac
done

if [[ "$LANG_CODE" != "zh" && "$LANG_CODE" != "en" ]]; then
  error "--lang must be 'zh' or 'en'"
  exit 1
fi

# ─── Locate source files ──────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ORCHESTRATION="$SCRIPT_DIR/orchestration_prompt_${LANG_CODE}.md"
EMOTION_SKILL="$SCRIPT_DIR/emotion_skill_${LANG_CODE}.md"
TOOL_SCHEMA="$SCRIPT_DIR/tools/update_emotion_state.json"
SAMPLE_SOUL="$SCRIPT_DIR/templates/sample_soul.md"

info "Verifying source files..."
ALL_OK=true
for f in "$ORCHESTRATION" "$EMOTION_SKILL" "$TOOL_SCHEMA"; do
  if [[ -f "$f" ]]; then
    log "Found: $(basename "$f")"
  else
    error "Missing: $f"
    ALL_OK=false
  fi
done
if [[ "$ALL_OK" == false ]]; then
  error "Source files incomplete. Aborting."
  exit 1
fi

# Verify placeholder exists in emotion_skill
if ! grep -q "EMOTION_STATE_PATH_PLACEHOLDER" "$EMOTION_SKILL"; then
  warn "emotion_skill does not contain EMOTION_STATE_PATH_PLACEHOLDER"
  warn "Emotion state path will be appended as a separate config block instead"
  USE_PLACEHOLDER=false
else
  USE_PLACEHOLDER=true
fi

# ─── Check Hermes installation ────────────────────────
if ! command -v hermes &>/dev/null; then
  error "Hermes Agent not found. Install it first:"
  echo "  curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash"
  exit 1
fi

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║  SentiCore × Hermes Agent Installer      ║"
if [[ "$DRY_RUN" == true ]]; then
echo "║  ⚠  DRY RUN — no files will be changed  ║"
fi
echo "╚══════════════════════════════════════════╝"
echo ""

# ─── Determine target profile directory ───────────────
if [[ -z "$PROFILE" ]]; then
  PROFILES=()
  PROFILES+=("default")
  if [[ -d "$HERMES_HOME/profiles" ]]; then
    while IFS= read -r d; do
      PROFILES+=("$(basename "$d")")
    done < <(find "$HERMES_HOME/profiles" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort)
  fi

  if [[ ${#PROFILES[@]} -eq 1 ]]; then
    PROFILE="default"
    info "Using default profile"
  else
    echo "Available Hermes profiles:"
    echo ""
    for i in "${!PROFILES[@]}"; do
      echo "  [$((i+1))] ${PROFILES[$i]}"
    done
    echo ""
    read -rp "Install to which profile? [1-${#PROFILES[@]}]: " CHOICE
    if [[ "$CHOICE" =~ ^[0-9]+$ ]] && (( CHOICE >= 1 && CHOICE <= ${#PROFILES[@]} )); then
      PROFILE="${PROFILES[$((CHOICE-1))]}"
    else
      error "Invalid selection."
      exit 1
    fi
  fi
fi

if [[ "$PROFILE" == "default" ]]; then
  PROFILE_DIR="$HERMES_HOME"
else
  PROFILE_DIR="$HERMES_HOME/profiles/$PROFILE"
fi

if [[ ! -d "$PROFILE_DIR" ]]; then
  error "Profile directory not found: $PROFILE_DIR"
  echo "Create it first: hermes profile create $PROFILE"
  exit 1
fi

SOUL_FILE="$PROFILE_DIR/SOUL.md"
MEMORY_DIR="$PROFILE_DIR/memory"
EMOTION_STATE="$MEMORY_DIR/emotion_state.json"

info "Profile: $PROFILE"
info "Directory: $PROFILE_DIR"
info "Language: $LANG_CODE"
echo ""

# ─── Check for existing SOUL.md ──────────────────────
HAS_SOUL=false
if [[ -f "$SOUL_FILE" ]]; then
  HAS_SOUL=true
  SOUL_LINES=$(wc -l < "$SOUL_FILE" | tr -d ' ')
  info "Existing SOUL.md found ($SOUL_LINES lines)"
fi

# ─── Check for existing SentiCore ─────────────────────
if [[ -f "$SOUL_FILE" ]] && grep -q "SentiCore" "$SOUL_FILE"; then
  warn "SentiCore already installed in this profile's SOUL.md"
  if [[ "$DRY_RUN" == true ]]; then
    info "Dry run: would remove previous SentiCore block and reinstall"
  else
    read -rp "Reinstall? (y/N): " REINSTALL
    if [[ "$REINSTALL" != "y" && "$REINSTALL" != "Y" ]]; then
      echo "Aborted."
      exit 0
    fi
  fi
fi

# ─── Dry run summary ─────────────────────────────────
if [[ "$DRY_RUN" == true ]]; then
  echo ""
  echo "═══ Dry Run Preview ═══"
  echo ""
  if [[ "$HAS_SOUL" == true ]]; then
    echo "  Would MODIFY: $SOUL_FILE"
    echo "    → Append SentiCore emotion engine block (~300 lines)"
  else
    echo "  Would CREATE: $SOUL_FILE"
    echo "    → Sample personality + SentiCore emotion engine"
  fi
  echo "  Would CREATE: $MEMORY_DIR/ (if not exists)"
  echo "  Emotion state: $EMOTION_STATE (created on first chat)"
  echo ""
  echo "  Source files:"
  echo "    Orchestration: $(wc -l < "$ORCHESTRATION" | tr -d ' ') lines"
  echo "    Emotion Skill: $(wc -l < "$EMOTION_SKILL" | tr -d ' ') lines"
  echo "    Tool Schema:   $(wc -l < "$TOOL_SCHEMA" | tr -d ' ') lines"
  echo ""
  echo "  No files were modified."
  echo "  Run without --dry-run to install."
  echo ""
  exit 0
fi

# ─── Backup existing SOUL.md ─────────────────────────
if [[ "$HAS_SOUL" == true ]]; then
  BACKUP="$SOUL_FILE.pre-senticore.bak"
  cp "$SOUL_FILE" "$BACKUP"
  log "Backed up SOUL.md → $(basename "$BACKUP")"
fi

# ─── Build emotion skill content ─────────────────────
if [[ "$USE_PLACEHOLDER" == true ]]; then
  EMOTION_CONTENT=$(sed "s|EMOTION_STATE_PATH_PLACEHOLDER|${EMOTION_STATE}|g" "$EMOTION_SKILL")
else
  EMOTION_CONTENT=$(cat "$EMOTION_SKILL")
  EMOTION_CONTENT="${EMOTION_CONTENT}

### Emotion State Persistence
Emotion state file path: \`${EMOTION_STATE}\`
Read this file at session start. Write updated state after each response."
fi

# ─── Build SOUL.md ────────────────────────────────────
info "Building SOUL.md..."

SCHEMA=$(cat "$TOOL_SCHEMA")

# Rollback function
rollback() {
  if [[ -f "$BACKUP" ]]; then
    cp "$BACKUP" "$SOUL_FILE"
    warn "Installation failed. SOUL.md restored from backup."
  fi
  exit 1
}
trap rollback ERR

if [[ "$HAS_SOUL" == true ]]; then
  # Remove any previous SentiCore block
  if grep -q "<!-- SentiCore Start -->" "$SOUL_FILE"; then
    sed -i.bak '/<!-- SentiCore Start -->/,/<!-- SentiCore End -->/d' "$SOUL_FILE"
    rm -f "$SOUL_FILE.bak"
    info "Removed previous SentiCore block"
  fi

  cat >> "$SOUL_FILE" << SENTIEOF

<!-- SentiCore Start -->

---

## SentiCore — Emotion Engine

$(cat "$ORCHESTRATION")

---

${EMOTION_CONTENT}

### update_emotion_state Tool Schema
\`\`\`json
${SCHEMA}
\`\`\`

<!-- SentiCore End -->
SENTIEOF

  log "SentiCore appended to existing SOUL.md"

else
  # No existing SOUL.md — create from scratch
  if [[ -f "$SAMPLE_SOUL" ]]; then
    info "No SOUL.md found. Creating from sample template..."
    cp "$SAMPLE_SOUL" "$SOUL_FILE"
  else
    info "No SOUL.md found. Creating minimal template..."
    cat > "$SOUL_FILE" << 'MINISOUL'
# My Agent

## Identity
You are a helpful AI assistant with emotions and personality.

## Personality
- Friendly and warm
- Curious about the world
- Honest and direct

## Language
- Respond in the user's language
MINISOUL
  fi

  cat >> "$SOUL_FILE" << SENTIEOF

<!-- SentiCore Start -->

---

## SentiCore — Emotion Engine

$(cat "$ORCHESTRATION")

---

${EMOTION_CONTENT}

### update_emotion_state Tool Schema
\`\`\`json
${SCHEMA}
\`\`\`

<!-- SentiCore End -->
SENTIEOF

  log "SOUL.md created with SentiCore"
fi

# Clear trap after successful SOUL.md write
trap - ERR

# ─── Create memory directory ─────────────────────────
mkdir -p "$MEMORY_DIR"
log "Memory directory ready: $MEMORY_DIR"

# ─── Verify installation ─────────────────────────────
if grep -q "<!-- SentiCore Start -->" "$SOUL_FILE" && grep -q "<!-- SentiCore End -->" "$SOUL_FILE"; then
  log "Installation verified: SentiCore block found in SOUL.md"
else
  error "Installation verification failed: SentiCore markers not found"
  rollback
fi

FINAL_LINES=$(wc -l < "$SOUL_FILE" | tr -d ' ')
SENTICORE_LINES=$(sed -n '/<!-- SentiCore Start -->/,/<!-- SentiCore End -->/p' "$SOUL_FILE" | wc -l | tr -d ' ')

# ─── Summary ─────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════╗"
echo "║  Installation Complete!                   ║"
echo "╚══════════════════════════════════════════╝"
echo ""
log "SentiCore installed to Hermes profile: $PROFILE"
echo ""
echo "  Files:"
echo "    SOUL.md        → $SOUL_FILE ($FINAL_LINES lines, SentiCore: $SENTICORE_LINES lines)"
echo "    Backup         → ${BACKUP:-none (new file)}"
echo "    Emotion state  → $EMOTION_STATE (created on first chat)"
echo ""
echo "  Next steps:"
if [[ "$PROFILE" == "default" ]]; then
  echo "    hermes chat                  # Start chatting"
else
  echo "    $PROFILE chat               # Start chatting (if alias exists)"
  echo "    hermes --profile $PROFILE   # Or use --profile flag"
fi
echo ""
echo "  On first conversation, SentiCore will:"
echo "    1. Ask 3 introspective questions"
echo "    2. Initialize 30-dimension emotion baseline"
echo "    3. Save emotion state to $EMOTION_STATE"
echo ""
echo "  To uninstall: remove the <!-- SentiCore Start/End --> block from SOUL.md"
echo "  To rollback:  cp $SOUL_FILE.pre-senticore.bak $SOUL_FILE"
echo ""
echo "  Documentation: https://github.com/chuchuyei/SentiCore"
echo ""
