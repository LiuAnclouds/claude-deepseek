param(
  [string] $InstallDir = "$env:LOCALAPPDATA\claude-deepseek",
  [switch] $PurgeConfig,
  [switch] $RemovePath
)

$ErrorActionPreference = 'Stop'

function Write-Step {
  param([string] $Message)
  Write-Host "[claude-deepseek] $Message"
}

$binDir = Join-Path $InstallDir 'bin'

if (Test-Path $InstallDir) {
  Remove-Item -LiteralPath $InstallDir -Recurse -Force
  Write-Step "Removed $InstallDir"
} else {
  Write-Step "$InstallDir was not present"
}

if ($RemovePath) {
  $current = [Environment]::GetEnvironmentVariable('Path', 'User')
  if ($current) {
    $items = $current -split ';' | Where-Object { $_ -and ($_ -ne $binDir) }
    [Environment]::SetEnvironmentVariable('Path', ($items -join ';'), 'User')
    Write-Step "Removed $binDir from the user PATH"
  }
}

if ($PurgeConfig) {
  $configDir = Join-Path $env:USERPROFILE '.config\claude-deepseek'
  if (Test-Path $configDir) {
    Remove-Item -LiteralPath $configDir -Recurse -Force
    Write-Step "Removed $configDir"
  }
}

Write-Step 'Native Claude Code was not removed. To remove it, run: npm uninstall -g @anthropic-ai/claude-code'
