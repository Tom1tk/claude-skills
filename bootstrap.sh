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

# ── 3. Done ───────────────────────────────────────────────────────────────────
echo ""
echo "All done! Run 'claude' to start and log in on first use."
