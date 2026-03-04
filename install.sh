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

echo ""
echo "Done! Skills installed to $CLAUDE_DIR"
echo "Run 'claude' in any project to use them."
