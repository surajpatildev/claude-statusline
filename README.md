# Terminus

A minimal, single-line statusline for [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

```
◆ Opus ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬ 42% │ ⌂ my-project ⎇ feat/login +689 −293 │ $4.42 ⏱ 26m
```

Cold steel + amber palette. Context bar changes color as usage climbs. Everything at a glance, nothing in the way.

## What you see

| Section | Info |
|---------|------|
| **Identity** | Model name with color-coded diamond (gold = Opus, blue = Sonnet, silver = Haiku) |
| **Context bar** | 20-char `▬` bar — blue < 70%, amber 70–89%, red 90%+ |
| **Workspace** | Project folder, git branch, staged/modified file counts |
| **Changes** | Total lines added/removed in the session |
| **Metrics** | Session cost (USD) and elapsed time |

## Setup

### 1. Install `jq`

The script uses [`jq`](https://jqlang.github.io/jq/) to parse the JSON data Claude Code sends to the statusline.

```bash
# macOS
brew install jq

# Ubuntu / Debian
sudo apt install jq

# Arch
sudo pacman -S jq
```

### 2. Copy the script

```bash
curl -fsSL https://raw.githubusercontent.com/surajpatildev/claude-statusline/main/statusline.sh -o ~/.claude/statusline.sh
chmod +x ~/.claude/statusline.sh
```

Or clone and copy:

```bash
git clone https://github.com/surajpatildev/claude-statusline.git
cp claude-statusline/statusline.sh ~/.claude/statusline.sh
chmod +x ~/.claude/statusline.sh
```

### 3. Configure Claude Code

Add this to `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh"
  }
}
```

The statusline appears after your next interaction with Claude Code.

## Customization

All tuning knobs are in the **Config** section near the top of the script:

```bash
GIT_TTL=5          # seconds between git refreshes
BAR_W=20           # progress bar width (chars)
PCT_WARN=70        # context % → warning color
PCT_CRIT=90        # context % → critical color
```

### Colors

The **Palette** section maps every color to a semantic role. Change any `\033[38;5;XXm` value using the [256-color chart](https://en.wikipedia.org/wiki/ANSI_escape_code#8-bit):

```bash
C_GOLD='\033[38;5;215m'       # opus dot · cost · modifications
C_BLUE='\033[38;5;75m'        # sonnet dot · branch
C_TEAL='\033[38;5;116m'       # additions
C_ROSE='\033[38;5;174m'       # deletions
```

## How it works

- Claude Code pipes JSON session data to the script via stdin on every update
- A single `jq` call extracts all fields (model, context %, cost, duration, line changes)
- Git info is cached per-session in `/tmp/claude-sl-git-*` with a 5-second TTL
- Session-scoped caches prevent cross-session contamination when running multiple Claude instances
- Cache writes are atomic (`tmp` + `mv`) to avoid partial reads
- Output uses `printf '%b'` for reliable ANSI escape handling across shells

## Requirements

- **bash** 3.2+ (ships with macOS and most Linux distros)
- **jq** (see install step above)
- **git** (optional — git info is skipped gracefully if not in a repo)

## License

MIT
