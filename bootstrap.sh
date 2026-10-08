#!/bin/bash
set -e

REPO_RAW="https://raw.githubusercontent.com/Tom1tk/claude-skills/main"

# ── 1. Install Claude Code ────────────────────────────────────────────────────
if command -v claude &>/dev/null; then
  echo "✓ Claude Code already installed ($(claude --version 2>/dev/null || echo 'version unknown'))"
else
  echo "Installing Claude Code..."
  curl -fsSL https://claude.ai/install.sh | bash
  echo "✓ Claude Code installed"
fi

# The native installer puts claude in ~/.local/bin, which may not be on PATH
# in this shell yet — install.sh needs it for updates and plugins
export PATH="$HOME/.local/bin:$PATH"

# ── 2. Install everything else (same as install.sh) ───────────────────────────
echo ""
curl -fsSL "$REPO_RAW/install.sh" | bash

echo "Run 'claude' to start and log in on first use."
