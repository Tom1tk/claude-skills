#!/bin/bash
set -e

REPO_RAW="https://raw.githubusercontent.com/Tom1tk/claude-skills/main"
CLAUDE_DIR="$HOME/.claude"
COMMANDS_DIR="$CLAUDE_DIR/commands"

# Update Claude Code if present — avoids known bugs on older versions
# (e.g. claude-hud's EXDEV install error) and unlocks newer features
# (e.g. outputStyle, added in 2.1.237)
if command -v claude &>/dev/null; then
  echo "Checking for Claude Code updates..."
  claude update || true
  echo ""
fi

echo "Installing Claude skills..."
mkdir -p "$COMMANDS_DIR"

# Install global CLAUDE.md — an existing one may hold machine-specific
# instructions, so only replace it if the user says so (default: keep)
TMP_CLAUDE_MD=$(mktemp)
curl -fsSL "$REPO_RAW/CLAUDE.md" -o "$TMP_CLAUDE_MD"
if [ ! -f "$CLAUDE_DIR/CLAUDE.md" ]; then
  mv "$TMP_CLAUDE_MD" "$CLAUDE_DIR/CLAUDE.md"
  echo "✓ CLAUDE.md installed"
elif cmp -s "$TMP_CLAUDE_MD" "$CLAUDE_DIR/CLAUDE.md"; then
  rm -f "$TMP_CLAUDE_MD"
  echo "✓ CLAUDE.md already up to date"
else
  reply=""
  # Under `curl | bash` stdin is the script, so ask on the terminal directly
  if (: </dev/tty) 2>/dev/null; then
    read -r -p "~/.claude/CLAUDE.md differs from the repo version. Replace it? [y/N] " reply </dev/tty || true
  fi
  if [[ "$reply" =~ ^[Yy] ]]; then
    mv "$TMP_CLAUDE_MD" "$CLAUDE_DIR/CLAUDE.md"
    echo "✓ CLAUDE.md replaced"
  else
    rm -f "$TMP_CLAUDE_MD"
    echo "• Kept existing CLAUDE.md"
  fi
fi

# Install commands from manifest
curl -fsSL "$REPO_RAW/manifest.txt" | while read cmd; do
  [ -z "$cmd" ] && continue
  curl -fsSL "$REPO_RAW/commands/${cmd}.md" -o "$COMMANDS_DIR/${cmd}.md"
  echo "✓ /$cmd installed"
done

# Install rules (preserving directory structure)
curl -fsSL "$REPO_RAW/rules-manifest.txt" | while read path; do
  [ -z "$path" ] && continue
  dest="$CLAUDE_DIR/$path"
  mkdir -p "$(dirname "$dest")"
  curl -fsSL "$REPO_RAW/$path" -o "$dest"
  echo "✓ $path installed"
done

# Install skills (preserving directory structure)
curl -fsSL "$REPO_RAW/skills-manifest.txt" | while read path; do
  [ -z "$path" ] && continue
  dest="$CLAUDE_DIR/$path"
  mkdir -p "$(dirname "$dest")"
  curl -fsSL "$REPO_RAW/$path" -o "$dest"
  echo "✓ $path installed"
done

# Merge settings.json additively: add keys that are missing, never change
# existing values (they may be environment-specific)
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
TMP_PATCH=$(mktemp)
curl -fsSL "$REPO_RAW/settings.json" -o "$TMP_PATCH"

if command -v python3 &>/dev/null; then
  if python3 - "$SETTINGS_FILE" "$TMP_PATCH" <<'PYEOF'
import json, sys
settings_path, patch_path = sys.argv[1], sys.argv[2]

def add_missing(base, patch):
    for k, v in patch.items():
        if k not in base:
            base[k] = v
        elif isinstance(base[k], dict) and isinstance(v, dict):
            add_missing(base[k], v)
    return base

try:
    with open(settings_path) as f:
        existing = json.load(f)
except FileNotFoundError:
    existing = {}
except json.JSONDecodeError as e:
    sys.exit(f"{settings_path} is not valid JSON ({e}) — leaving it untouched")

with open(patch_path) as f:
    patch = json.load(f)

with open(settings_path, 'w') as f:
    json.dump(add_missing(existing, patch), f, indent=2)
    f.write('\n')
PYEOF
  then
    echo "✓ settings.json merged (existing values kept)"
  else
    echo "⚠ settings.json merge skipped"
  fi
elif command -v jq &>/dev/null; then
  if [ ! -f "$SETTINGS_FILE" ]; then
    cp "$TMP_PATCH" "$SETTINGS_FILE"
    echo "✓ settings.json installed"
  elif jq -s '.[1] * .[0]' "$SETTINGS_FILE" "$TMP_PATCH" > "${SETTINGS_FILE}.tmp"; then
    mv "${SETTINGS_FILE}.tmp" "$SETTINGS_FILE"
    echo "✓ settings.json merged (existing values kept)"
  else
    rm -f "${SETTINGS_FILE}.tmp"
    echo "⚠ settings.json is not valid JSON — leaving it untouched"
  fi
else
  echo "⚠ python3/jq not found — skipping settings.json merge"
fi
rm -f "$TMP_PATCH"

# Install (or update) plugins from manifest: "<plugin> <owner/repo>" per line
if command -v claude &>/dev/null; then
  curl -fsSL "$REPO_RAW/plugins-manifest.txt" | while read -r name source; do
    [ -z "$name" ] && continue
    if claude plugin install "$name" --marketplace "$source" -y </dev/null >/dev/null 2>&1 \
      && claude plugin update "$name" </dev/null >/dev/null 2>&1; then
      echo "✓ plugin $name installed"
    else
      echo "⚠ plugin $name failed — try: claude plugin install $name --marketplace $source"
    fi
  done
else
  echo "⚠ claude not found on PATH — skipping plugin install"
fi

if ! command -v node &>/dev/null; then
  echo ""
  echo "⚠ Node.js not found on PATH."
  echo "  ponytail and claude-hud run lifecycle hooks via Node — without it,"
  echo "  ponytail's mode tracking won't activate (non-blocking hook error on"
  echo "  every prompt) and claude-hud's status line won't render."
  echo "  Install Node.js, then confirm it's on PATH for non-interactive"
  echo "  shells too (nvm/Nix users: this is a common gotcha)."
elif command -v claude &>/dev/null; then
  # Point the status line at claude-hud using claude-hud's own setup script,
  # which writes the right command for this platform. A status line that
  # isn't claude-hud's is left alone.
  HUD_DIR=$(claude plugin list --json 2>/dev/null | node -e '
    const p = JSON.parse(require("fs").readFileSync(0, "utf8")).find(x => x.id === "claude-hud@claude-hud");
    console.log(p ? p.installPath : "");' || true)
  if [ -n "$HUD_DIR" ]; then
    HUD_PLAN=$(node "$HUD_DIR/scripts/setup.mjs" inspect --shell posix 2>/dev/null | node -e '
      const fs = require("fs");
      const r = JSON.parse(fs.readFileSync(0, "utf8"));
      const s = fs.existsSync(r.settingsPath) ? JSON.parse(fs.readFileSync(r.settingsPath, "utf8")) : {};
      console.log(r.existing === "other" ? "keep" : s.statusLine?.command === r.command ? "current" : "install");' 2>/dev/null || true)
    case "$HUD_PLAN" in
      install) if node "$HUD_DIR/scripts/setup.mjs" install --shell posix >/dev/null; then
                 echo "✓ claude-hud status line configured"
               else
                 echo "⚠ claude-hud status line setup failed — run /claude-hud:setup in Claude Code"
               fi ;;
      current) echo "✓ claude-hud status line already configured" ;;
      keep)    echo "• Kept existing status line (claude-hud not applied)" ;;
      *)       echo "⚠ claude-hud status line setup failed — run /claude-hud:setup in Claude Code" ;;
    esac
  fi
fi

echo ""
echo "Done! Installed to $CLAUDE_DIR — restart Claude Code to pick up changes."
