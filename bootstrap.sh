#!/bin/bash
set -e

REPO_RAW="https://raw.githubusercontent.com/Tom1tk/claude-skills/main"
CLAUDE_DIR="$HOME/.claude"
COMMANDS_DIR="$CLAUDE_DIR/commands"

# ── 1. Install Claude Code ────────────────────────────────────────────────────
if command -v claude &>/dev/null; then
  echo "✓ Claude Code already installed ($(claude --version 2>/dev/null || echo 'version unknown'))"
else
  echo "Installing Claude Code..."
  curl -fsSL https://claude.ai/install.sh | bash
  echo "✓ Claude Code installed"
fi

# ── 2. Install skills ─────────────────────────────────────────────────────────
echo ""
echo "Installing Claude skills..."
mkdir -p "$COMMANDS_DIR"

curl -fsSL "$REPO_RAW/CLAUDE.md" -o "$CLAUDE_DIR/CLAUDE.md"
echo "✓ CLAUDE.md installed"

curl -fsSL "$REPO_RAW/manifest.txt" | while read cmd; do
  [ -z "$cmd" ] && continue
  curl -fsSL "$REPO_RAW/commands/${cmd}.md" -o "$COMMANDS_DIR/${cmd}.md"
  echo "✓ /$cmd installed"
done

# ── 3. Merge settings (claude-hud plugin) ────────────────────────────────────
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
TMP_PATCH=$(mktemp)
curl -fsSL "$REPO_RAW/settings.json" -o "$TMP_PATCH"

if command -v python3 &>/dev/null; then
  python3 - "$SETTINGS_FILE" "$TMP_PATCH" <<'PYEOF'
import json, sys
settings_path, patch_path = sys.argv[1], sys.argv[2]

def deep_merge(base, patch):
    for k, v in patch.items():
        if k in base and isinstance(base[k], dict) and isinstance(v, dict):
            deep_merge(base[k], v)
        else:
            base[k] = v
    return base

try:
    with open(settings_path) as f:
        existing = json.load(f)
except (FileNotFoundError, json.JSONDecodeError):
    existing = {}

with open(patch_path) as f:
    patch = json.load(f)

with open(settings_path, 'w') as f:
    json.dump(deep_merge(existing, patch), f, indent=2)
    f.write('\n')
PYEOF
  echo "✓ settings.json merged (claude-hud)"
elif command -v jq &>/dev/null; then
  if [ -f "$SETTINGS_FILE" ]; then
    jq -s '.[0] * .[1]' "$SETTINGS_FILE" "$TMP_PATCH" > "${SETTINGS_FILE}.tmp" \
      && mv "${SETTINGS_FILE}.tmp" "$SETTINGS_FILE"
  else
    cp "$TMP_PATCH" "$SETTINGS_FILE"
  fi
  echo "✓ settings.json merged (claude-hud)"
else
  echo "⚠ python3/jq not found — skipping settings.json merge"
fi
rm -f "$TMP_PATCH"

# ── 4. Done ───────────────────────────────────────────────────────────────────
echo ""
echo "All done! Run 'claude' to start and log in on first use."
echo ""
echo "To finish claude-hud setup, open Claude Code and run:"
echo "  /plugin install claude-hud"
echo "Then restart Claude Code."
