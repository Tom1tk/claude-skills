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

The install script will also configure the [claude-hud](https://github.com/jarrodwatts/claude-hud) status line plugin. After it completes, open Claude Code and run:

```
/plugin install claude-hud
```

Then restart Claude Code. The HUD will appear in your terminal status line automatically.

## What gets installed

### Global config

| Path | Purpose |
|------|---------|
| `~/.claude/CLAUDE.md` | Global instructions: workflow orchestration, task management, core principles |
| `~/.claude/settings.json` | Plugin config: claude-hud status line, marketplace registration |

### Plugins

| Plugin | What it does |
|--------|-------------|
| [claude-hud](https://github.com/jarrodwatts/claude-hud) | Terminal status line showing context fill %, token rate, active tools, and git branch. Requires `/plugin install claude-hud` on first use. |

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

`settings.json` in this repo is deep-merged into `~/.claude/settings.json` on install — existing keys are preserved. To add a new plugin or setting, edit `settings.json` and the install scripts will pick it up on next run.

## Re-installing / updating

Re-run the one-liner. It overwrites existing files with the latest from `main`.

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

## Credits

Rules and skills sourced from: [affaan-m/everything-claude-code](https://github.com/affaan-m/everything-claude-code/).
Claude.md sourced from: [forrestchang/andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills/blob/main/CLAUDE.md)
