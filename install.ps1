$ErrorActionPreference = 'Stop'

$RepoRaw    = "https://raw.githubusercontent.com/Tom1tk/claude-skills/main"
$ClaudeDir  = "$HOME\.claude"
$CommandsDir = "$ClaudeDir\commands"

# Update Claude Code if present — avoids known bugs on older versions
# (e.g. claude-hud's "no JavaScript runtime was found" setup error) and
# unlocks newer features (e.g. outputStyle, added in 2.1.237)
if (Get-Command claude -ErrorAction SilentlyContinue) {
    Write-Host "Checking for Claude Code updates..."
    claude update
    Write-Host ""
}

Write-Host "Installing Claude skills..."
New-Item -ItemType Directory -Force -Path $CommandsDir | Out-Null

# Install global CLAUDE.md — an existing one may hold machine-specific
# instructions, so only replace it if the user says so (default: keep)
$claudeMd = "$ClaudeDir\CLAUDE.md"
$tmpClaudeMd = [System.IO.Path]::GetTempFileName()
Invoke-WebRequest -Uri "$RepoRaw/CLAUDE.md" -OutFile $tmpClaudeMd
if (-not (Test-Path $claudeMd)) {
    Move-Item $tmpClaudeMd $claudeMd
    Write-Host "v CLAUDE.md installed"
} elseif ((Get-FileHash $tmpClaudeMd).Hash -eq (Get-FileHash $claudeMd).Hash) {
    Remove-Item $tmpClaudeMd
    Write-Host "v CLAUDE.md already up to date"
} else {
    $reply = ''
    try { $reply = Read-Host "~/.claude/CLAUDE.md differs from the repo version. Replace it? [y/N]" } catch {}
    if ($reply -match '^[Yy]') {
        Move-Item -Force $tmpClaudeMd $claudeMd
        Write-Host "v CLAUDE.md replaced"
    } else {
        Remove-Item $tmpClaudeMd
        Write-Host "- Kept existing CLAUDE.md"
    }
}

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

# Merge settings.json additively: add keys that are missing, never change
# existing values (they may be environment-specific)
$SettingsFile = "$ClaudeDir\settings.json"
$patch = (Invoke-WebRequest -Uri "$RepoRaw/settings.json").Content | ConvertFrom-Json

function Add-MissingJson($Base, $Patch) {
    foreach ($prop in $Patch.PSObject.Properties) {
        $existingProp = $Base.PSObject.Properties[$prop.Name]
        if (-not $existingProp) {
            $Base | Add-Member -MemberType NoteProperty -Name $prop.Name -Value $prop.Value
        } elseif ($existingProp.Value -is [System.Management.Automation.PSCustomObject] -and $prop.Value -is [System.Management.Automation.PSCustomObject]) {
            Add-MissingJson -Base $existingProp.Value -Patch $prop.Value | Out-Null
        }
    }
    return $Base
}

$existing = New-Object PSObject
$settingsValid = $true
if (Test-Path $SettingsFile) {
    try {
        $parsed = (Get-Content $SettingsFile -Raw) | ConvertFrom-Json
        if ($parsed) { $existing = $parsed }
    } catch {
        $settingsValid = $false
    }
}

if ($settingsValid) {
    $merged = Add-MissingJson -Base $existing -Patch $patch
    ($merged | ConvertTo-Json -Depth 20) | Set-Content $SettingsFile
    Write-Host "v settings.json merged (existing values kept)"
} else {
    Write-Host "! settings.json is not valid JSON - leaving it untouched"
}

# Run a native command silently and return its exit code. Windows PowerShell
# 5.1 throws on redirected stderr output when ErrorActionPreference is Stop.
function Invoke-Quiet([scriptblock]$Block) {
    $ErrorActionPreference = 'Continue'
    & $Block *> $null
    return $LASTEXITCODE
}

# Install (or update) plugins from manifest: "<plugin> <owner/repo>" per line
$hasClaude = [bool](Get-Command claude -ErrorAction SilentlyContinue)
if ($hasClaude) {
    $pluginsManifest = (Invoke-WebRequest -Uri "$RepoRaw/plugins-manifest.txt").Content
    foreach ($line in ($pluginsManifest -split "`r?`n")) {
        $name, $source = -split $line
        if (-not $name) { continue }
        $code = Invoke-Quiet { claude plugin install $name --marketplace $source -y }
        if ($code -eq 0) { $code = Invoke-Quiet { claude plugin update $name } }
        if ($code -eq 0) {
            Write-Host "v plugin $name installed"
        } else {
            Write-Host "! plugin $name failed - try: claude plugin install $name --marketplace $source"
        }
    }
} else {
    Write-Host "! claude not found on PATH - skipping plugin install"
}

if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Host ""
    Write-Host "! Node.js not found on PATH."
    Write-Host "  ponytail and claude-hud run lifecycle hooks via Node - without it,"
    Write-Host "  ponytail's mode tracking won't activate and claude-hud's status"
    Write-Host "  line won't render."
    Write-Host "  Install Node.js LTS: winget install OpenJS.NodeJS.LTS"
} elseif ($hasClaude) {
    # Point the status line at claude-hud using claude-hud's own setup script,
    # which writes the right command for the shell Claude Code runs it in:
    # Git Bash when it's installed, otherwise PowerShell. A status line that
    # isn't claude-hud's is left alone.
    $gitBash = $env:CLAUDE_CODE_GIT_BASH_PATH
    if (-not $gitBash) {
        $git = Get-Command git -ErrorAction SilentlyContinue
        if ($git) { $gitBash = Join-Path (Split-Path (Split-Path $git.Source)) 'bin\bash.exe' }
    }
    $hudShell = if ($gitBash -and (Test-Path $gitBash)) { 'gitbash' } else { 'powershell' }

    $hud = ((claude plugin list --json) -join "`n" | ConvertFrom-Json) |
        ForEach-Object { $_ } | Where-Object { $_.id -eq 'claude-hud@claude-hud' } | Select-Object -First 1
    if ($hud) {
        $hudSetup = Join-Path $hud.installPath 'scripts\setup.mjs'
        try {
            $report = (node $hudSetup inspect --shell $hudShell) -join "`n" | ConvertFrom-Json
            $current = $null
            if (Test-Path $report.settingsPath) {
                $current = ((Get-Content $report.settingsPath -Raw) | ConvertFrom-Json).statusLine.command
            }
            if ($report.existing -eq 'other') {
                Write-Host "- Kept existing status line (claude-hud not applied)"
            } elseif ($current -eq $report.command) {
                Write-Host "v claude-hud status line already configured"
            } else {
                $code = Invoke-Quiet { node $hudSetup install --shell $hudShell }
                if ($code -ne 0) { throw "setup.mjs exited with $code" }
                Write-Host "v claude-hud status line configured ($hudShell)"
            }
        } catch {
            Write-Host "! claude-hud status line setup failed - run /claude-hud:setup in Claude Code"
        }
    }
}

Write-Host ""
Write-Host "Done! Installed to $ClaudeDir - restart Claude Code to pick up changes."
