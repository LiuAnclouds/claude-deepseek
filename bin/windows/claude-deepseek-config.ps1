param(
  [switch] $Show,
  [switch] $Unset,
  [switch] $Path
)

$ErrorActionPreference = 'Stop'
$ConfigFile = if ($env:CLAUDE_DEEPSEEK_CONFIG) {
  $env:CLAUDE_DEEPSEEK_CONFIG
} else {
  Join-Path $env:USERPROFILE '.config\claude-deepseek\env'
}

if ($Path) {
  Write-Output $ConfigFile
  exit 0
}

if ($Show) {
  if (Test-Path $ConfigFile) {
    Write-Output "DeepSeek API key is configured at $ConfigFile"
  } else {
    Write-Output 'DeepSeek API key is not configured. Run claude-deepseek-config.'
  }
  exit 0
}

if ($Unset) {
  if (Test-Path $ConfigFile) {
    Remove-Item -LiteralPath $ConfigFile -Force
  }
  Write-Output "Removed $ConfigFile"
  exit 0
}

$secure = Read-Host 'DeepSeek API Key' -AsSecureString
$bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
try {
  $plain = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
} finally {
  [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
}

if (-not $plain) {
  throw 'API key is empty.'
}

$dir = Split-Path -Parent $ConfigFile
New-Item -ItemType Directory -Force -Path $dir | Out-Null
$content = @"
# Claude DeepSeek API config
ANTHROPIC_AUTH_TOKEN="$plain"
"@
Set-Content -LiteralPath $ConfigFile -Value $content -Encoding ASCII
Write-Output "Saved DeepSeek API key to $ConfigFile"
Write-Output 'You can now run claude-deepseek'
