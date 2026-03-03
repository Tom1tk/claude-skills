$ErrorActionPreference = 'Stop'

$RepoRaw    = "https://raw.githubusercontent.com/Tom1tk/claude-skills/main"
$ClaudeDir  = "$HOME\.claude"
$CommandsDir = "$ClaudeDir\commands"

Write-Host "Installing Claude skills..."
New-Item -ItemType Directory -Force -Path $CommandsDir | Out-Null

# Install global CLAUDE.md
Invoke-WebRequest -Uri "$RepoRaw/CLAUDE.md" -OutFile "$ClaudeDir\CLAUDE.md"
Write-Host "v CLAUDE.md installed"

# Install commands from manifest
$manifest = (Invoke-WebRequest -Uri "$RepoRaw/manifest.txt").Content
foreach ($cmd in ($manifest -split "`r?`n")) {
    $cmd = $cmd.Trim()
    if ($cmd -eq '') { continue }
    Invoke-WebRequest -Uri "$RepoRaw/commands/$cmd.md" -OutFile "$CommandsDir\$cmd.md"
    Write-Host "v /$cmd installed"
}

Write-Host ""
Write-Host "Done! Skills installed to $ClaudeDir"
Write-Host "Open a new Claude Code session to use them."
