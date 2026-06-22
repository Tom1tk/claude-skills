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

# Merge settings.json (plugin config: claude-hud, ponytail, improve)
$SettingsFile = "$ClaudeDir\settings.json"
$patch = (Invoke-WebRequest -Uri "$RepoRaw/settings.json").Content | ConvertFrom-Json

function Merge-JsonObject($Base, $Patch) {
    foreach ($prop in $Patch.PSObject.Properties) {
        $name = $prop.Name
        $value = $prop.Value
        $existingProp = $Base.PSObject.Properties[$name]
        if ($existingProp -and $existingProp.Value -is [System.Management.Automation.PSCustomObject] -and $value -is [System.Management.Automation.PSCustomObject]) {
            Merge-JsonObject -Base $existingProp.Value -Patch $value
        } elseif ($existingProp) {
            $Base.$name = $value
        } else {
            $Base | Add-Member -MemberType NoteProperty -Name $name -Value $value
        }
    }
    return $Base
}

if (Test-Path $SettingsFile) {
    try {
        $existing = (Get-Content $SettingsFile -Raw) | ConvertFrom-Json
    } catch {
        $existing = New-Object PSObject
    }
} else {
    $existing = New-Object PSObject
}

$merged = Merge-JsonObject -Base $existing -Patch $patch
($merged | ConvertTo-Json -Depth 20) | Set-Content $SettingsFile
Write-Host "v settings.json merged (plugins)"

Write-Host ""
Write-Host "Done! Skills installed to $ClaudeDir"
Write-Host "Open a new Claude Code session to use them."
Write-Host ""
Write-Host "To finish plugin setup, open Claude Code and run:"
Write-Host "  /plugin install claude-hud@claude-hud"
Write-Host "  /plugin install ponytail@ponytail"
Write-Host "  /plugin install improve@improve"
Write-Host "Then restart Claude Code."
