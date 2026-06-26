param(
  [string] $ClaudeCodeVersion = $env:CLAUDE_CODE_VERSION,
  [string] $InstallDir = "$env:LOCALAPPDATA\claude-horizon",
  [switch] $SkipClaudeCode,
  [switch] $NoPath
)

$ErrorActionPreference = 'Stop'

if (-not $ClaudeCodeVersion) {
  $ClaudeCodeVersion = '2.1.153'
}

function Write-Step {
  param([string] $Message)
  Write-Host "[claude-horizon] $Message"
}

function Test-Node {
  $node = Get-Command node -ErrorAction SilentlyContinue
  if (-not $node) {
    return $false
  }

  $major = & node -p "Number(process.versions.node.split('.')[0])"
  return ([int] $major -ge 18)
}

function Add-UserPath {
  param([string] $PathToAdd)

  $current = [Environment]::GetEnvironmentVariable('Path', 'User')
  $items = @()
  if ($current) {
    $items = $current -split ';' | Where-Object { $_ }
  }

  if ($items -notcontains $PathToAdd) {
    $newPath = if ($current) { "$current;$PathToAdd" } else { $PathToAdd }
    [Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
    $env:Path = "$env:Path;$PathToAdd"
    Write-Step "Added $PathToAdd to the user PATH"
  } else {
    Write-Step "$PathToAdd is already in the user PATH"
  }
}

if (-not (Test-Node)) {
  throw 'Node.js 18 or newer is required on Windows. Install Node.js 22 LTS from https://nodejs.org, then rerun install.ps1.'
}

Write-Step "Node.js detected: $(node -v)"

if (-not $SkipClaudeCode) {
  $npm = Get-Command npm.cmd -ErrorAction SilentlyContinue | Select-Object -First 1
  if (-not $npm) {
    $npm = Get-Command npm -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
  }
  if (-not $npm) {
    throw 'npm was not found. Reinstall Node.js with npm enabled.'
  }

  Write-Step "Installing @anthropic-ai/claude-code@$ClaudeCodeVersion"
  & $npm.Source install -g "@anthropic-ai/claude-code@$ClaudeCodeVersion"
  if ($LASTEXITCODE -ne 0) {
    throw 'npm failed to install Claude Code.'
  }
}

$binDir = Join-Path $InstallDir 'bin'
$libexecDir = Join-Path $InstallDir 'libexec'
New-Item -ItemType Directory -Force -Path $binDir | Out-Null
New-Item -ItemType Directory -Force -Path $libexecDir | Out-Null

$sourceDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$windowsBin = Join-Path $sourceDir 'bin\windows'

Copy-Item -LiteralPath (Join-Path $windowsBin 'claude-horizon.cmd') -Destination $binDir -Force
Copy-Item -LiteralPath (Join-Path $windowsBin 'claude-horizon-config.cmd') -Destination $binDir -Force
Copy-Item -LiteralPath (Join-Path $windowsBin 'claude-horizon-models.cmd') -Destination $binDir -Force
Copy-Item -LiteralPath (Join-Path $windowsBin 'claude-horizon.ps1') -Destination $libexecDir -Force
Copy-Item -LiteralPath (Join-Path $windowsBin 'claude-horizon-config.ps1') -Destination $libexecDir -Force
Copy-Item -LiteralPath (Join-Path $windowsBin 'claude-horizon-models.ps1') -Destination $libexecDir -Force

if (-not $NoPath) {
  Add-UserPath $binDir
}

Write-Step "Installed Windows commands to $binDir"
Write-Step 'Next: open a new terminal, run claude-horizon-config, then claude-horizon'
