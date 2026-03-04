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

# Install rules (preserving directory structure)
$rulesManifest = (Invoke-WebRequest -Uri "$RepoRaw/rules-manifest.txt").Content
foreach ($path in ($rulesManifest -split "`r?`n")) {
    $path = $path.Trim()
    if ($path -eq '') { continue }
    $dest = "$ClaudeDir\$($path -replace '/', '\')"
    New-Item -ItemType Directory -Force -Path (Split-Path $dest) | Out-Null
    Invoke-WebRequest -Uri "$RepoRaw/$path" -OutFile $dest
    Write-Host "v $path installed"
}

# Install skills (preserving directory structure)
$skillsManifest = (Invoke-WebRequest -Uri "$RepoRaw/skills-manifest.txt").Content
foreach ($path in ($skillsManifest -split "`r?`n")) {
    $path = $path.Trim()
    if ($path -eq '') { continue }
    $dest = "$ClaudeDir\$($path -replace '/', '\')"
    New-Item -ItemType Directory -Force -Path (Split-Path $dest) | Out-Null
    Invoke-WebRequest -Uri "$RepoRaw/$path" -OutFile $dest
    Write-Host "v $path installed"
}

Write-Host ""
Write-Host "Done! Skills installed to $ClaudeDir"
Write-Host "Open a new Claude Code session to use them."
