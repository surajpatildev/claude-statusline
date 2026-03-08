#!/bin/bash
# Terminus — Claude Code statusline installer
# Usage: curl -fsSL https://raw.githubusercontent.com/surajpatildev/claude-statusline/main/install.sh | bash
set -e

REPO="https://raw.githubusercontent.com/surajpatildev/claude-statusline/main"
CLAUDE_DIR="$HOME/.claude"
SCRIPT="$CLAUDE_DIR/statusline.sh"
SETTINGS="$CLAUDE_DIR/settings.json"

# ── Colors ───────────────────────────────────────────────────

RST='\033[0m'
BLD='\033[1m'
DIM='\033[38;5;243m'
OK='\033[38;5;75m'
WARN='\033[38;5;172m'
ERR='\033[38;5;131m'
GOLD='\033[38;5;215m'

step() { printf "${OK}  ✓${RST} %s\n" "$1"; }
warn() { printf "${WARN}  !${RST} %s\n" "$1"; }
fail() { printf "${ERR}  ✗${RST} %s\n" "$1"; exit 1; }

# ── Header ───────────────────────────────────────────────────

printf "\n${GOLD}${BLD}  Terminus${RST} ${DIM}— Claude Code statusline${RST}\n\n"

# ── Preflight ────────────────────────────────────────────────

command -v jq  >/dev/null 2>&1 || fail "jq is required. Install: brew install jq (macOS) or apt install jq (Linux)"
command -v curl >/dev/null 2>&1 || fail "curl is required"
command -v git >/dev/null 2>&1 || warn "git not found — git info will be skipped in the statusline"

# ── Install ──────────────────────────────────────────────────

mkdir -p "$CLAUDE_DIR"

curl -fsSL "$REPO/statusline.sh" -o "$SCRIPT"
chmod +x "$SCRIPT"
step "Downloaded statusline.sh"

# Merge statusLine config into settings.json (preserves existing keys)
SL_CONFIG='{"type":"command","command":"~/.claude/statusline.sh"}'

if [ -f "$SETTINGS" ]; then
  jq --argjson sl "$SL_CONFIG" '.statusLine = $sl' "$SETTINGS" > "${SETTINGS}.tmp" \
    && mv "${SETTINGS}.tmp" "$SETTINGS"
  step "Updated settings.json"
else
  printf '{\n  "statusLine": %s\n}\n' "$SL_CONFIG" | jq . > "$SETTINGS"
  step "Created settings.json"
fi

# ── Done ─────────────────────────────────────────────────────

printf "\n${DIM}  ┌─────────────────────────────────────────────────────────┐${RST}\n"
printf "${DIM}  │${RST} ${BLD}Installed.${RST} Start a Claude Code session to see it.     ${DIM}│${RST}\n"
printf "${DIM}  │${RST} Config tunables are at the top of ~/.claude/statusline.sh ${DIM}│${RST}\n"
printf "${DIM}  └─────────────────────────────────────────────────────────┘${RST}\n\n"
