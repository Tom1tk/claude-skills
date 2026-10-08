# claude-skills

Personal Claude Code skills registry. Installs global instructions, slash commands, language rules, and auto-invoked skills into `~/.claude` on any machine.

## Install

**Fresh machine** — installs Claude Code first, then the skills:

```bash
curl -fsSL https://raw.githubusercontent.com/Tom1tk/claude-skills/main/bootstrap.sh | bash
```

**Claude Code already installed** — just install the skills:

```bash
curl -fsSL https://raw.githubusercontent.com/Tom1tk/claude-skills/main/install.sh | bash
```

**Windows (PowerShell):**

```powershell
irm https://raw.githubusercontent.com/Tom1tk/claude-skills/main/install.ps1 | iex
```

The install script also installs the plugins in `plugins-manifest.txt` and sets up claude-hud's status line, so there's nothing to run by hand. Restart Claude Code afterwards to pick everything up.

`bootstrap.sh` installs Claude Code if it's missing, then runs `install.sh`, so both paths install the same things.

**Optional: orchestrator mode** — Opus plans and audits, subagents run on Haiku (see [Orchestrator mode](#orchestrator-mode-optional)):

```bash
curl -fsSL https://raw.githubusercontent.com/Tom1tk/claude-skills/main/orchestrator.sh | bash                    # enable
curl -fsSL https://raw.githubusercontent.com/Tom1tk/claude-skills/main/orchestrator.sh | bash -s -- --disable    # disable
```

## My personal usage

```bash
useradd -m -s /bin/bash user
passwd user
usermod -aG sudo user
su - user

CLAUDE_CODE_NO_FLICKER=1 claude --dangerously-skip-permissions

OR

IS_SANDBOX=1 CLAUDE_CODE_NO_FLICKER=1 claude --dangerously-skip-permissions
```

## Orchestrator mode (optional)

An opt-in drop-in, separate from the default install: Opus 5.5 plans and audits, and every subagent runs on Haiku 5.5 at xhigh effort.

```bash
# enable
curl -fsSL https://raw.githubusercontent.com/Tom1tk/claude-skills/main/orchestrator.sh | bash
# disable
curl -fsSL https://raw.githubusercontent.com/Tom1tk/claude-skills/main/orchestrator.sh | bash -s -- --disable
```

```powershell
# enable
irm https://raw.githubusercontent.com/Tom1tk/claude-skills/main/orchestrator.ps1 | iex
# disable
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/Tom1tk/claude-skills/main/orchestrator.ps1))) -Disable
```

Enabling it:

| Change | Why |
|--------|-----|
| `model: opus`, `effortLevel: medium`, `advisorModel: opus` | Opus 5.5 main session; Haiku subagents (and the main session) can consult an Opus advisor at decision points |
| `PreToolUse` hook on `Agent` | Rewrites every subagent call to `model: haiku`, `effort: xhigh` — a hard force, regardless of what the main session asks for |
| `Agent(Plan)` in `permissions.deny` | Planning stays with the main session (deny rules apply even with `--dangerously-skip-permissions`) |
| `~/.claude/rules/orchestration.md` | When to do work yourself vs delegate, how to brief a subagent, and auditing every result |
| `UserPromptSubmit` and `PostToolUse` reminder hooks | A one-line delegation nudge with each prompt, and an "unverified — check it" nudge each time a subagent returns |

Disabling restores the `model`, `effortLevel`, and `advisorModel` you had before, and removes only what enabling added. Requires Node.js and Claude Code v2.1.293+ (the script runs `claude update`). Check which model each subagent ran on with `/tasks`.

## What gets installed

### Global config

| Path | Purpose |
|------|---------|
| `~/.claude/CLAUDE.md` | Global instructions: workflow orchestration, task management, core principles |
| `~/.claude/settings.json` | Defaults: `outputStyle: Concise`, `autoCompactWindow: 200000` |

### Plugins

Installed (or updated) with `claude plugin install`, from `plugins-manifest.txt` — one `<plugin> <owner/repo>` per line.

| Plugin | What it does |
|--------|-------------|
| [claude-hud](https://github.com/jarrodwatts/claude-hud) | Terminal status line showing context fill %, token rate, active tools, and git branch. |
| [ponytail](https://github.com/DietrichGebert/ponytail) | "Lazy senior dev" mode — pushes toward the simplest solution that works (stdlib first, no unrequested abstractions) before writing code. |
| [improve](https://github.com/shadcn/improve) | Audits a codebase (bugs, security, perf, tech debt) and writes self-contained implementation plans to `plans/` for another agent or model to execute. Never edits code itself. |

claude-hud's status line is written by claude-hud's own setup script, which picks the right command for the platform (bash/zsh, Git Bash, or PowerShell on Windows). If you already have a status line that isn't claude-hud's, it's left alone.

**Troubleshooting:** ponytail and claude-hud both run via Node.js. If `node` isn't on `PATH` (including the non-interactive shell PATH — a common gotcha with nvm/Nix), ponytail's mode tracking silently fails to activate and claude-hud's status line won't render. The install scripts warn if `node` is missing. The status line points at the `node` binary found at install time, so after switching Node versions, re-run the install script (or `/claude-hud:setup`). Older Claude Code versions can also hit an `EXDEV: cross-device link not permitted` error installing claude-hud on Linux — the install scripts run `claude update` first to avoid it; if you still hit it, run `mkdir -p ~/.cache/tmp && TMPDIR=~/.cache/tmp claude` and retry the plugin install in that session.

### Commands (slash commands)

| Command | Purpose |
|---------|---------|
| `/review` | Code review for logic, security, and style |
| `/refactor` | Improve readability without changing behaviour |
| `/explain` | Clear step-by-step explanation of code |
| `/ticket` | Generate an engineering ticket from current work |
| `/debug` | Systematic root-cause analysis and minimal fix |
| `/security-audit` | OWASP-style audit with severity, location, and fix per finding |
| `/commit` | Write a Conventional Commits message from staged diff and commit |
| `/dead-code` | Find unused functions, imports, and unreachable branches |
| `/dependency-audit` | Check for CVEs, abandoned packages, and unsafe version pins |
| `/readme-update` | Update README to reflect recent code changes |

### Rules (auto-loaded by file type)

Rules load automatically when Claude works on matching files — no manual invocation needed.

| Rule set | Applies to | Contents |
|----------|-----------|----------|
| `rules/common/coding-style.md` | All files | Immutability, file organisation, error handling, input validation |
| `rules/common/hooks.md` | All files | Hook types, auto-accept guidance, TodoWrite best practices |
| `rules/common/patterns.md` | All files | Repository pattern, API response format, skeleton project approach |
| `rules/python/coding-style.md` | `**/*.py`, `**/*.pyi` | PEP 8, type annotations, black/isort/ruff |
| `rules/python/hooks.md` | `**/*.py`, `**/*.pyi` | Python-specific hook patterns |
| `rules/python/patterns.md` | `**/*.py`, `**/*.pyi` | Python idioms (see `python-patterns` skill) |
| `rules/swift/coding-style.md` | `**/*.swift` | SwiftFormat, SwiftLint, immutability with `let`, naming |
| `rules/swift/hooks.md` | `**/*.swift` | Swift-specific hook patterns |
| `rules/swift/patterns.md` | `**/*.swift` | Swift concurrency, actors, protocol-oriented patterns |

### Skills (auto-invoked by context)

Skills are loaded automatically when Claude detects the relevant context — no slash command needed.

| Skill | Activates when... |
|-------|------------------|
| `liquid-glass-design` | Building iOS 26+ UI with Liquid Glass effects in SwiftUI, UIKit, or WidgetKit |
| `python-patterns` | Writing Python — provides idiomatic patterns, async, testing, packaging |
| `swift-actor-persistence` | Implementing Swift actors with persistent state |
| `swift-protocol-di-testing` | Using protocol-based dependency injection in Swift |
| `swiftui-patterns` | Building SwiftUI views — MVVM, state management, navigation |

## Usage

Inside any Claude Code session:

```
/review       Review the current file or selected code
/refactor     Refactor for readability and simplicity
/explain      Explain what the code does and why
/ticket       Draft an engineering ticket for the current task
/debug        Diagnose an error or unexpected behaviour
/security-audit  Audit code for security vulnerabilities
/commit       Write a commit message and commit staged changes
/dead-code    Find unused code across the project
/dependency-audit  Audit dependencies for CVEs and risk
/readme-update  Update the README to match current code
```

Rules and skills activate automatically — no commands needed.

## Adding a new command

1. Create `commands/<name>.md` with the prompt
2. Add `<name>` to `manifest.txt`
3. Push — the install script picks it up automatically

## Adding rules or skills

- **Rule**: add the file under `rules/<lang>/` and append its path to `rules-manifest.txt`
- **Skill**: add `skills/<name>/SKILL.md` and append its path to `skills-manifest.txt`

## Updating settings

`settings.json` in this repo is merged into `~/.claude/settings.json` additively: keys you don't have yet are added, and values you already have are never changed (so environment-specific settings survive). If `~/.claude/settings.json` isn't valid JSON, it's left untouched. To add a plugin, add a line to `plugins-manifest.txt`.

## Re-installing / updating

Re-run the one-liner. Commands, rules, and skills are overwritten with the latest from `main`, and plugins are updated. If `~/.claude/CLAUDE.md` differs from the repo's version, you're asked whether to replace it (default: no, keep yours).

## Credits

Rules and skills sourced from: [affaan-m/everything-claude-code](https://github.com/affaan-m/everything-claude-code/).

Claude.md sourced from: [forrestchang/andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills/blob/main/CLAUDE.md).
