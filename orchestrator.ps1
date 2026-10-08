# Orchestrator mode (opt-in): Opus 5.5 plans and audits, every subagent runs
# on Haiku 5.5 at xhigh effort, with an Opus advisor.
#   enable:  irm https://raw.githubusercontent.com/Tom1tk/claude-skills/main/orchestrator.ps1 | iex
#   disable: & ([scriptblock]::Create((irm https://raw.githubusercontent.com/Tom1tk/claude-skills/main/orchestrator.ps1))) -Disable
param([switch]$Disable)
$ErrorActionPreference = 'Stop'

$RepoRaw   = "https://raw.githubusercontent.com/Tom1tk/claude-skills/main"
$ClaudeDir = "$HOME\.claude"
$ModeDir   = "$ClaudeDir\orchestrator"

if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Host "! Node.js is required (orchestrator mode runs its hooks with node)"
    Write-Host "  Install Node.js LTS: winget install OpenJS.NodeJS.LTS"
    return
}

if ($Disable) {
    if (-not (Test-Path "$ModeDir\setup.mjs")) {
        Write-Host "Orchestrator mode isn't enabled - nothing to do"
        return
    }
    node "$ModeDir\setup.mjs" disable
    if ($LASTEXITCODE -ne 0) { return }
    Remove-Item -Force -ErrorAction SilentlyContinue "$ClaudeDir\rules\orchestration.md"
    Remove-Item -Recurse -Force $ModeDir
    Write-Host "v Orchestrator mode disabled, previous model/effort/advisor restored"
    Write-Host "Restart Claude Code to apply."
    return
}

# Haiku 5.5 needs Claude Code v2.1.293 or later
if (Get-Command claude -ErrorAction SilentlyContinue) {
    Write-Host "Checking for Claude Code updates..."
    claude update
    Write-Host ""
}

New-Item -ItemType Directory -Force -Path $ModeDir, "$ClaudeDir\rules" | Out-Null
foreach ($f in 'setup.mjs', 'haiku-subagents.mjs', 'reminders.mjs') {
    Invoke-WebRequest -Uri "$RepoRaw/orchestrator/$f" -OutFile "$ModeDir\$f"
}
node "$ModeDir\setup.mjs" enable
if ($LASTEXITCODE -ne 0) { return }
Invoke-WebRequest -Uri "$RepoRaw/orchestrator/orchestration.md" -OutFile "$ClaudeDir\rules\orchestration.md"

Write-Host "v Orchestrator mode enabled:"
Write-Host "  main session: Opus 5.5, medium effort, Opus advisor"
Write-Host "  subagents:    Haiku 5.5, xhigh effort (enforced by a hook)"
Write-Host "  Plan subagent blocked, so planning stays with the main session"
Write-Host "Restart Claude Code to apply. Check subagent models with /tasks."
