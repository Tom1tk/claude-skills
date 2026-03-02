# claude-skills

Personal Claude Code skills registry. Installs global instructions and custom slash commands into `~/.claude` on any machine.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/Tom1tk/claude-skills/main/install.sh | bash
```

That's it. Open a new Claude Code session and the commands are available.

## What gets installed

| Path | Purpose |
|------|---------|
| `~/.claude/CLAUDE.md` | Global instructions applied to every Claude session |
| `~/.claude/commands/review.md` | `/review` — code review for logic, security, and style |
| `~/.claude/commands/refactor.md` | `/refactor` — improve readability without changing behaviour |
| `~/.claude/commands/explain.md` | `/explain` — clear step-by-step explanation of code |
| `~/.claude/commands/ticket.md` | `/ticket` — generate an engineering ticket from current work |

## Usage

Inside any Claude Code session:

```
/review       Review the current file or selected code
/refactor     Refactor for readability and simplicity
/explain      Explain what the code does and why
/ticket       Draft an engineering ticket for the current task
```

## Adding a new command

1. Create `commands/<name>.md` with the prompt
2. Add `<name>` to `manifest.txt`
3. Push — the install script picks it up automatically

## Re-installing / updating

Re-run the one-liner. It overwrites existing files with the latest from `main`.
