param(
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]] $Args
)

$ErrorActionPreference = 'Stop'

$ConfigDir = if ($env:CLAUDE_HORIZON_CONFIG_DIR) {
  $env:CLAUDE_HORIZON_CONFIG_DIR
} else {
  Join-Path $env:USERPROFILE '.config\claude-horizon'
}

$ModelsFile = if ($env:CLAUDE_HORIZON_MODELS_FILE) {
  $env:CLAUDE_HORIZON_MODELS_FILE
} else {
  Join-Path $ConfigDir 'models'
}

function Write-Usage {
  Write-Output @'
Usage:
  claude-horizon-models --list                  List current model assignments
  claude-horizon-models --set ROLE MODEL        Set a role to a model
  claude-horizon-models --reset                 Reset to defaults

Roles:
  main      ANTHROPIC_MODEL (default: HORIZON-DeepSeek-Pro)
  opus      ANTHROPIC_DEFAULT_OPUS_MODEL
  sonnet    ANTHROPIC_DEFAULT_SONNET_MODEL
  haiku     ANTHROPIC_DEFAULT_HAIKU_MODEL
  subagent  CLAUDE_CODE_SUBAGENT_MODEL

Defaults:
  main/opus/haiku: HORIZON-DeepSeek-Pro
  sonnet/subagent: HORIZON-GLM

Examples:
  claude-horizon-models --set sonnet HORIZON-GLM
  claude-horizon-models --set subagent HORIZON-DeepSeek
'@
}

function Get-RoleEnv {
  param([string] $RoleName)
  switch ($RoleName) {
    'main'     { return 'ANTHROPIC_MODEL' }
    'opus'     { return 'ANTHROPIC_DEFAULT_OPUS_MODEL' }
    'sonnet'   { return 'ANTHROPIC_DEFAULT_SONNET_MODEL' }
    'haiku'    { return 'ANTHROPIC_DEFAULT_HAIKU_MODEL' }
    'subagent' { return 'CLAUDE_CODE_SUBAGENT_MODEL' }
    default    { throw "Unknown role '$RoleName'. Valid roles: main, opus, sonnet, haiku, subagent" }
  }
}

function List-Models {
  Write-Output 'Current model assignments:'
  Write-Output '  main/opus/haiku: HORIZON-DeepSeek-Pro'
  Write-Output '  sonnet/subagent: HORIZON-GLM'
  if (Test-Path $ModelsFile) {
    Write-Output ''
    Write-Output "Overrides from $ModelsFile :"
    Get-Content -LiteralPath $ModelsFile | ForEach-Object {
      if ($_ -match '^\s*(?:export\s+)?([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.+)$') {
        Write-Output "  $($Matches[1])=$($Matches[2])"
      }
    }
  }
}

function Set-Model {
  param([string] $RoleName, [string] $ModelName)

  if (-not $RoleName -or -not $ModelName) {
    throw 'Usage: claude-horizon-models --set <ROLE> <MODEL>'
  }

  $envVar = Get-RoleEnv -RoleName $RoleName

  New-Item -ItemType Directory -Force -Path $ConfigDir | Out-Null

  # Remove old entry for this env var, then append new one
  if (Test-Path $ModelsFile) {
    $lines = Get-Content -LiteralPath $ModelsFile | Where-Object { $_ -notmatch "^export\s+$([regex]::Escape($envVar))=" -and $_ -notmatch "^$([regex]::Escape($envVar))=" }
    $lines | Set-Content -LiteralPath $ModelsFile -Encoding ASCII
  }

  "export ${envVar}='${ModelName}'" | Add-Content -LiteralPath $ModelsFile -Encoding ASCII

  Write-Output "Set $RoleName -> $ModelName"
  Write-Output 'Run claude-horizon to apply.'
}

function Reset-Models {
  if (Test-Path $ModelsFile) {
    Remove-Item -LiteralPath $ModelsFile -Force
  }
  Write-Output 'Reset to defaults (main/opus/haiku: HORIZON-DeepSeek-Pro, sonnet/subagent: HORIZON-GLM).'
}

# Parse arguments manually (same syntax as Linux version)
$i = 0
while ($i -lt $Args.Count) {
  switch ($Args[$i]) {
    '--list' {
      List-Models
      exit 0
    }
    '--set' {
      $role = if ($i + 1 -lt $Args.Count) { $Args[$i + 1] } else { '' }
      $model = if ($i + 2 -lt $Args.Count) { $Args[$i + 2] } else { '' }
      Set-Model -RoleName $role -ModelName $model
      exit 0
    }
    '--reset' {
      Reset-Models
      exit 0
    }
    '-h' { Write-Usage; exit 0 }
    '--help' { Write-Usage; exit 0 }
    default {
      Write-Usage
      exit 2
    }
  }
  $i++
}

# Default: show current assignments
List-Models