#!/bin/bash
# Claude Code Statusline — "Terminus"
# Cold steel palette, slim ▬ bar, single line.
#
# ◆ Opus ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬ 42% │ ⌂ my-project ⎇ feat/login +689 −293 │ $4.42 ⏱ 26m

INPUT=$(</dev/stdin)
NOW=$(date +%s)

# ── Palette ──────────────────────────────────────────────────

RST='\033[0m'
BLD='\033[1m'

C_W='\033[38;5;252m'          # primary text
C_DIM='\033[38;5;243m'        # secondary / duration
C_SEP='\033[38;5;238m'        # group separator
C_TRACK='\033[38;5;236m'      # bar empty track

C_GOLD='\033[38;5;215m'       # opus dot · cost · modifications
C_BLUE='\033[38;5;75m'        # sonnet dot · branch
C_TEAL='\033[38;5;116m'       # additions
C_ROSE='\033[38;5;174m'       # deletions
C_SILVER='\033[38;5;249m'     # haiku dot

C_BAR_OK='\033[38;5;33m'      # bar <70%
C_BAR_WARN='\033[38;5;172m'   # bar 70–89%
C_BAR_CRIT='\033[38;5;131m'   # bar ≥90%

SEP=" ${C_SEP}│${RST} "

# ── Config ───────────────────────────────────────────────────

GIT_TTL=5          # seconds between git refreshes
BAR_W=20           # progress bar width (chars)
PCT_WARN=70        # context % → warning color
PCT_CRIT=90        # context % → critical color

# ── Helpers ──────────────────────────────────────────────────

file_mtime() { stat -f %m "$1" 2>/dev/null || stat -c %Y "$1" 2>/dev/null || echo 0; }
is_fresh()   { [ -f "$1" ] && [ $((NOW - $(file_mtime "$1"))) -le "$2" ]; }

# ── Data (single jq call) ───────────────────────────────────

{
  read -r MODEL_ID
  read -r MODEL_RAW
  read -r DIR
  read -r PCT
  read -r COST
  read -r DUR_MS
  read -r L_ADD
  read -r L_DEL
  read -r SESSION_ID
} < <(printf '%s' "$INPUT" | jq -r '
  (.model.id // "unknown"),
  (.model.display_name // "Claude"),
  (.workspace.current_dir // .cwd // ""),
  (.context_window.used_percentage // 0 | floor),
  (.cost.total_cost_usd // 0),
  (.cost.total_duration_ms // 0),
  (.cost.total_lines_added // 0),
  (.cost.total_lines_removed // 0),
  (.session_id // "default")
')

MODEL="${MODEL_RAW%% *}"
PROJECT="${DIR##*/}"
: "${PROJECT:=~}"
: "${PCT:=0}" "${DUR_MS:=0}" "${L_ADD:=0}" "${L_DEL:=0}"

# Session-scoped cache key
SID="${SESSION_ID:0:12}"

# ── Model dot ────────────────────────────────────────────────

case "$MODEL_ID" in
  *opus*)   DOT="$C_GOLD" ;;
  *sonnet*) DOT="$C_BLUE" ;;
  *haiku*)  DOT="$C_SILVER" ;;
  *)        DOT="$C_DIM" ;;
esac

# ── Git (cached, session-scoped) ────────────────────────────

GIT_CACHE="/tmp/claude-sl-git-${SID}"

if ! is_fresh "$GIT_CACHE" "$GIT_TTL"; then
  if [ -n "$DIR" ] && git -C "$DIR" rev-parse --git-dir >/dev/null 2>&1; then
    b=$(git -C "$DIR" branch --show-current 2>/dev/null)
    sg=$(git -C "$DIR" diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
    mo=$(git -C "$DIR" diff --numstat 2>/dev/null | wc -l | tr -d ' ')
    printf '%s' "${b}|${sg}|${mo}" > "${GIT_CACHE}.tmp" && mv "${GIT_CACHE}.tmp" "$GIT_CACHE"
  else
    printf '%s' "||" > "${GIT_CACHE}.tmp" && mv "${GIT_CACHE}.tmp" "$GIT_CACHE"
  fi
fi

IFS='|' read -r GIT_BR GIT_STAGED GIT_MOD < "$GIT_CACHE"
: "${GIT_STAGED:=0}" "${GIT_MOD:=0}"

# ── Bar (precomputed, no forks) ──────────────────────────────

BAR_FULL='▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬'
FILLED=$((PCT * BAR_W / 100))
[ "$FILLED" -gt "$BAR_W" ] && FILLED=$BAR_W
EMPTY=$((BAR_W - FILLED))

if   [ "$PCT" -ge "$PCT_CRIT" ]; then BAR_C="$C_BAR_CRIT"; PCT_C="$C_BAR_CRIT"
elif [ "$PCT" -ge "$PCT_WARN" ]; then BAR_C="$C_BAR_WARN"; PCT_C="$C_BAR_WARN"
else                                   BAR_C="$C_BAR_OK";   PCT_C="$C_W"
fi

BAR=""
[ "$FILLED" -gt 0 ] && BAR="${BAR_C}${BAR_FULL:0:FILLED}${RST}"
[ "$EMPTY"  -gt 0 ] && BAR="${BAR}${C_TRACK}${BAR_FULL:0:EMPTY}${RST}"

# ── Duration ─────────────────────────────────────────────────

DUR_S=$((DUR_MS / 1000))
if   [ "$DUR_S" -lt 60 ];   then DUR="${DUR_S}s"
elif [ "$DUR_S" -lt 3600 ]; then
  DUR="$((DUR_S / 60))m"; [ $((DUR_S % 60)) -gt 0 ] && DUR="${DUR}$((DUR_S % 60))s"
else DUR="$((DUR_S / 3600))h$(((DUR_S % 3600) / 60))m"
fi

# ── Assemble ─────────────────────────────────────────────────

G1="${DOT}◆${RST} ${BLD}${C_W}${MODEL}${RST} ${BAR} ${PCT_C}${PCT}%${RST}"

G2="${C_DIM}⌂${RST} ${C_W}${PROJECT}${RST}"
[ -n "$GIT_BR" ]         && G2="${G2}  ${C_BLUE}⎇ ${GIT_BR}${RST}"
[ "$GIT_STAGED" -gt 0 ]  && G2="${G2} ${C_TEAL}+${GIT_STAGED}${RST}"
[ "$GIT_MOD"    -gt 0 ]  && G2="${G2} ${C_GOLD}~${GIT_MOD}${RST}"
[ "$L_ADD" -gt 0 ]       && G2="${G2}  ${C_TEAL}+${L_ADD}${RST}"
[ "$L_DEL" -gt 0 ]       && G2="${G2} ${C_ROSE}−${L_DEL}${RST}"

G3=""
if [ "$COST" != "0" ]; then
  printf -v COST_FMT '$%.2f' "$COST"
  G3="${C_GOLD}${COST_FMT}${RST}"
fi
if [ "$DUR_MS" -gt 0 ]; then
  [ -n "$G3" ] && G3="${G3}  "
  G3="${G3}${C_DIM}⏱ ${DUR}${RST}"
fi

LINE="${G1}${SEP}${G2}"
[ -n "$G3" ] && LINE="${LINE}${SEP}${G3}"
printf '%b\n' "$LINE"
