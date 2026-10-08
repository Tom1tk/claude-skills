#!/bin/bash
# Orchestrator mode (opt-in): Opus 5.5 plans and audits, every subagent runs
# on Haiku 5.5 at xhigh effort, with an Opus advisor.
#   enable:  curl -fsSL https://raw.githubusercontent.com/Tom1tk/claude-skills/main/orchestrator.sh | bash
#   disable: curl -fsSL https://raw.githubusercontent.com/Tom1tk/claude-skills/main/orchestrator.sh | bash -s -- --disable
set -e

REPO_RAW="https://raw.githubusercontent.com/Tom1tk/claude-skills/main"
CLAUDE_DIR="$HOME/.claude"
MODE_DIR="$CLAUDE_DIR/orchestrator"

if ! command -v node &>/dev/null; then
  echo "⚠ Node.js is required (orchestrator mode runs its hooks with node)"
  exit 1
fi

if [ "$1" = "--disable" ]; then
  if [ ! -f "$MODE_DIR/setup.mjs" ]; then
    echo "Orchestrator mode isn't enabled — nothing to do"
    exit 0
  fi
  node "$MODE_DIR/setup.mjs" disable
  rm -f "$CLAUDE_DIR/rules/orchestration.md"
  rm -rf "$MODE_DIR"
  echo "✓ Orchestrator mode disabled, previous model/effort/advisor restored"
  echo "Restart Claude Code to apply."
  exit 0
fi

# Haiku 5.5 needs Claude Code v2.1.293 or later
if command -v claude &>/dev/null; then
  echo "Checking for Claude Code updates..."
  claude update || true
  echo ""
fi

mkdir -p "$MODE_DIR" "$CLAUDE_DIR/rules"
for f in setup.mjs haiku-subagents.mjs reminders.mjs; do
  curl -fsSL "$REPO_RAW/orchestrator/$f" -o "$MODE_DIR/$f"
done
node "$MODE_DIR/setup.mjs" enable
curl -fsSL "$REPO_RAW/orchestrator/orchestration.md" -o "$CLAUDE_DIR/rules/orchestration.md"

echo "✓ Orchestrator mode enabled:"
echo "  main session: Opus 5.5, medium effort, Opus advisor"
echo "  subagents:    Haiku 5.5, xhigh effort (enforced by a hook)"
echo "  Plan subagent blocked, so planning stays with the main session"
echo "Restart Claude Code to apply. Check subagent models with /tasks."
