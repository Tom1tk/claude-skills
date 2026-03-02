#!/bin/bash
set -e

REPO_RAW="https://raw.githubusercontent.com/Tom1tk/claude-skills/main"
CLAUDE_DIR="$HOME/.claude"
COMMANDS_DIR="$CLAUDE_DIR/commands"

echo "Installing Claude skills..."
mkdir -p "$COMMANDS_DIR"

# Install global CLAUDE.md
curl -fsSL "$REPO_RAW/CLAUDE.md" -o "$CLAUDE_DIR/CLAUDE.md"
echo "✓ CLAUDE.md installed"

# Install commands from manifest
curl -fsSL "$REPO_RAW/manifest.txt" | while read cmd; do
  [ -z "$cmd" ] && continue
  curl -fsSL "$REPO_RAW/commands/${cmd}.md" -o "$COMMANDS_DIR/${cmd}.md"
  echo "✓ /$cmd installed"
done

echo ""
echo "Done! Skills installed to $CLAUDE_DIR"
echo "Run 'claude' in any project to use them."
