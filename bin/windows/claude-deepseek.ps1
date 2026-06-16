param(
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]] $Args
)

$ErrorActionPreference = 'Stop'

$ConfigFile = if ($env:CLAUDE_DEEPSEEK_CONFIG) {
  $env:CLAUDE_DEEPSEEK_CONFIG
} else {
  Join-Path $env:USERPROFILE '.config\claude-deepseek\env'
}

if (Test-Path $ConfigFile) {
  $lines = Get-Content -LiteralPath $ConfigFile -ErrorAction Stop
  foreach ($line in $lines) {
    if ($line -match '^\s*export\s+([A-Za-z_][A-Za-z0-9_]*)=(.*)$') {
      $name = $Matches[1]
      $value = $Matches[2].Trim()
      if ($value.StartsWith("'") -and $value.EndsWith("'")) {
        $value = $value.Substring(1, $value.Length - 2).Replace("''", "'")
      }
      Set-Item -Path "Env:$name" -Value $value
    } elseif ($line -match '^\s*([A-Z0-9_]+)\s*=\s*(.+)$') {
      Set-Item -Path "Env:$($Matches[1])" -Value $Matches[2].Trim().Trim('"')
    } elseif ($line.Trim() -and -not $line.TrimStart().StartsWith('#')) {
      $env:ANTHROPIC_AUTH_TOKEN = $line.Trim()
    }
  }
}

if (-not $env:ANTHROPIC_BASE_URL) {
  $env:ANTHROPIC_BASE_URL = 'https://api.deepseek.com/anthropic'
}
if (-not $env:ANTHROPIC_MODEL) {
  $env:ANTHROPIC_MODEL = 'deepseek-v4-pro[1m]'
}
if (-not $env:ANTHROPIC_DEFAULT_OPUS_MODEL) {
  $env:ANTHROPIC_DEFAULT_OPUS_MODEL = 'deepseek-v4-pro[1m]'
}
if (-not $env:ANTHROPIC_DEFAULT_SONNET_MODEL) {
  $env:ANTHROPIC_DEFAULT_SONNET_MODEL = 'deepseek-v4-pro[1m]'
}
if (-not $env:ANTHROPIC_DEFAULT_HAIKU_MODEL) {
  $env:ANTHROPIC_DEFAULT_HAIKU_MODEL = 'deepseek-v4-pro[1m]'
}
if (-not $env:CLAUDE_CODE_SUBAGENT_MODEL) {
  $env:CLAUDE_CODE_SUBAGENT_MODEL = 'deepseek-v4-pro[1m]'
}
if (-not $env:CLAUDE_CODE_EFFORT_LEVEL) {
  $env:CLAUDE_CODE_EFFORT_LEVEL = 'max'
}

$PassthroughWithoutAuth = $false
foreach ($arg in $Args) {
  if ($arg -in @('--version', '-v', '--help', '-h')) {
    $PassthroughWithoutAuth = $true
    break
  }
}

if ($PassthroughWithoutAuth) {
  $claude = Get-Command claude.cmd -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
  if (-not $claude) {
    $claude = Get-Command claude -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
  }
  if (-not $claude) {
    throw 'Claude Code is not installed. Run install.ps1 first.'
  }
  & $claude.Source @Args
  exit $LASTEXITCODE
}

if (-not $env:ANTHROPIC_AUTH_TOKEN -and $env:DEEPSEEK_API_KEY) {
  $env:ANTHROPIC_AUTH_TOKEN = $env:DEEPSEEK_API_KEY
}

if (-not $env:ANTHROPIC_AUTH_TOKEN) {
  if ($Host.Name -eq 'ConsoleHost') {
    $secure = Read-Host 'DeepSeek API Key' -AsSecureString
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try {
      $env:ANTHROPIC_AUTH_TOKEN = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
    } finally {
      [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    }
  } else {
    throw 'No DeepSeek API key configured. Run claude-deepseek-config.'
  }
}

$claude = Get-Command claude.cmd -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $claude) {
  $claude = Get-Command claude -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
}
if (-not $claude) {
  throw 'Claude Code is not installed. Run install.ps1 first.'
}

& $claude.Source @Args
