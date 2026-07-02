# Claude DeepSeek

<p align="center">
  <strong>Run Claude Code with DeepSeek's Anthropic-compatible API on Linux boards and Windows desktops.</strong>
</p>

<p align="center">
  <a href="#linux-quick-start"><img alt="Linux" src="https://img.shields.io/badge/Linux-supported-2ea44f?style=for-the-badge"></a>
  <a href="#windows-quick-start"><img alt="Windows" src="https://img.shields.io/badge/Windows-supported-0078d4?style=for-the-badge&logo=windows&logoColor=white"></a>
  <a href="#requirements"><img alt="Node.js 18+" src="https://img.shields.io/badge/Node.js-18%2B-43853d?style=for-the-badge&logo=node.js&logoColor=white"></a>
  <a href="https://api-docs.deepseek.com/quick_start/agent_integrations/claude_code"><img alt="DeepSeek" src="https://img.shields.io/badge/DeepSeek-Claude%20Code-0f172a?style=for-the-badge"></a>
  <a href="LICENSE"><img alt="License" src="https://img.shields.io/badge/License-MIT-blue?style=for-the-badge"></a>
</p>

<p align="center">
  <a href="#linux-quick-start">Linux</a> |
  <a href="#windows-quick-start">Windows</a> |
  <a href="#what-it-installs">What It Installs</a> |
  <a href="#api-key-management">API Key Management</a> |
  <a href="#linux-board-notes">Linux Board Notes</a> |
  <a href="#troubleshooting">Troubleshooting</a>
</p>

---

`claude-deepseek` is a small launcher that keeps the native `claude` command
intact and adds a dedicated DeepSeek-backed command:

```bash
claude            # native Anthropic Claude Code
claude-deepseek   # Claude Code routed to DeepSeek
```

It follows DeepSeek's official Claude Code integration by setting
`ANTHROPIC_BASE_URL` to DeepSeek's Anthropic-compatible endpoint and selecting
DeepSeek's strongest Claude Code model by default.

> Native Claude Code stays available as `claude`. DeepSeek-backed execution is
> always explicit through `claude-deepseek`.

## Why

Linux development boards and Windows desktops often need a repeatable way to
bootstrap Claude Code without hand-editing shell profiles on every device. This
project packages the working pattern into installable commands:

<table>
  <tr>
    <td width="33%">
      <h3>Separate Command</h3>
      <p>Leaves <code>claude</code> untouched and adds <code>claude-deepseek</code> for DeepSeek.</p>
    </td>
    <td width="33%">
      <h3>One-Time Key Setup</h3>
      <p>Stores the DeepSeek API key locally with user-only file permissions.</p>
    </td>
    <td width="33%">
      <h3>Board Ready</h3>
      <p>Can install Claude Code, add Windows shims, and provide an optional HTTPS clock bootstrapper for boards.</p>
    </td>
  </tr>
</table>

## Linux Quick Start

Clone and install:

```bash
git clone https://github.com/LiuAnclouds/claude-deepseek.git
cd claude-deepseek
chmod +x install.sh
./install.sh
```

Configure your DeepSeek API key once:

```bash
claude-deepseek-config
```

Start Claude Code through DeepSeek:

```bash
claude-deepseek
```

The first run should open the normal Claude Code interface, but API requests go
to DeepSeek's Anthropic-compatible endpoint.

## Linux One-Line Install

For fresh boards:

```bash
curl -fsSL https://raw.githubusercontent.com/LiuAnclouds/claude-deepseek/main/install.sh | sh
```

If the board has a bad system clock and TLS certificates fail, use the full
clone flow and install the optional HTTPS time sync service:

```bash
git clone https://github.com/LiuAnclouds/claude-deepseek.git
cd claude-deepseek
chmod +x install.sh
./install.sh --install-time-sync
```

## Requirements

| Requirement | Notes |
| --- | --- |
| Linux | Debian, Ubuntu, Raspberry Pi OS, and most systemd-based board images are supported. |
| Windows | Windows 10/11 with PowerShell 5.1+ or PowerShell 7+. |
| CPU | `x86_64`, `aarch64/arm64`, and `armv7l` are supported for automatic Node.js installation. |
| Node.js | Claude Code requires Node.js 18 or newer. The installer can bootstrap official Node.js 22 builds. |
| npm | Used to install `@anthropic-ai/claude-code`. |
| Network | The board must be able to reach `api.deepseek.com` over HTTPS. |

## What It Installs

The installer adds two commands under `/usr/local/bin` by default:

| Command | Purpose |
| --- | --- |
| `claude-deepseek` | Launch Claude Code with DeepSeek endpoint and model environment variables. |
| `claude-deepseek-config` | Save, show, or remove the DeepSeek API key. |

It also installs Claude Code when needed:

```bash
npm install -g @anthropic-ai/claude-code@2.1.153
```

The native `claude` command is intentionally left alone.

## Default Model

`claude-deepseek` uses DeepSeek Pro as the default model and keeps Flash
available for lighter Claude Code roles:

```bash
ANTHROPIC_BASE_URL=https://api.deepseek.com/anthropic
ANTHROPIC_MODEL=deepseek-v4-pro[1m]
ANTHROPIC_DEFAULT_OPUS_MODEL=deepseek-v4-pro[1m]
ANTHROPIC_DEFAULT_SONNET_MODEL=deepseek-v4-flash
ANTHROPIC_DEFAULT_HAIKU_MODEL=deepseek-v4-flash
CLAUDE_CODE_SUBAGENT_MODEL=deepseek-v4-flash
CLAUDE_CODE_EFFORT_LEVEL=max
```

You can override any value for a single run:

```bash
ANTHROPIC_MODEL='deepseek-v4-flash' claude-deepseek
```

## API Key Management

Save or replace your key:

```bash
claude-deepseek-config
```

Check whether a key is configured:

```bash
claude-deepseek-config --show
```

Print the config path:

```bash
claude-deepseek-config --path
```

Remove the saved key:

```bash
claude-deepseek-config --unset
```

The key is stored at:

```text
~/.config/claude-deepseek/env
```

The directory is created with mode `700`, and the key file is written with mode
`600`. The command never prints the saved key back to the terminal.

For CI or temporary sessions, you can skip saved config:

```bash
DEEPSEEK_API_KEY='sk-...' claude-deepseek --print 'hello'
```

or:

```bash
ANTHROPIC_AUTH_TOKEN='sk-...' claude-deepseek --print 'hello'
```

## Windows Quick Start

Install from PowerShell:

```powershell
git clone https://github.com/LiuAnclouds/claude-deepseek.git
cd claude-deepseek
.\install.cmd
```

`install.cmd` launches the PowerShell installer with `-ExecutionPolicy Bypass`,
so it works on machines where local `.ps1` scripts are restricted.

PowerShell users can also call the installer directly:

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

Configure your DeepSeek API key once:

```powershell
claude-deepseek-config
```

Start Claude Code through DeepSeek:

```powershell
claude-deepseek
```

The Windows installer adds `%LOCALAPPDATA%\claude-deepseek\bin` to the user
PATH. Open a new terminal after installation if the command is not immediately
available in the current session.

Only `.cmd` shims are placed in the PATH directory. The PowerShell scripts live
under `%LOCALAPPDATA%\claude-deepseek\libexec` and are launched with
`-ExecutionPolicy Bypass`, so normal `claude-deepseek` usage is not blocked by a
restricted PowerShell execution policy.

Windows keeps the native `claude` command untouched. `claude-deepseek` is the
DeepSeek-backed entry point.

### Windows API Key Location

The saved key lives at:

```text
%USERPROFILE%\.config\claude-deepseek\env
```

To remove it:

```powershell
claude-deepseek-config -Unset
```

## Installation Options

Linux:

```bash
./install.sh [options]
```

| Option | Description |
| --- | --- |
| `--install-node` | Install official Node.js even when an existing Node.js is present. |
| `--no-install-node` | Do not install Node.js automatically. |
| `--skip-claude-code` | Only install the DeepSeek launcher/config commands. |
| `--install-time-sync` | Install optional HTTPS Date-header clock bootstrap service. |

Windows:

```powershell
.\install.cmd [-ClaudeCodeVersion 2.1.153] [-SkipClaudeCode] [-NoPath]
```

| Parameter | Description |
| --- | --- |
| `-ClaudeCodeVersion` | Claude Code npm version to install. Default: `2.1.153`. |
| `-InstallDir` | User install directory. Default: `%LOCALAPPDATA%\claude-deepseek`. |
| `-SkipClaudeCode` | Only install the DeepSeek launcher/config commands. |
| `-NoPath` | Do not modify the user PATH. |

Environment variables:

| Variable | Default | Description |
| --- | --- | --- |
| `CLAUDE_CODE_VERSION` | `2.1.153` | Claude Code npm version to install. |
| `NODE_MAJOR` | `22` | Node.js major release for automatic install. |
| `INSTALL_PREFIX` | `/usr/local` | Install prefix for commands. |
| `BIN_DIR` | `$INSTALL_PREFIX/bin` | Command install directory. |

Example:

```bash
CLAUDE_CODE_VERSION=2.1.153 NODE_MAJOR=22 ./install.sh --install-node
```

## Linux Board Notes

### Bad Clock / TLS Errors

Some boards boot with a clock such as `2000-01-01`, which causes npm, curl, and
TLS clients to fail with errors like:

```text
CERT_NOT_YET_VALID
certificate is not yet valid
```

If NTP is blocked or unavailable, install the optional HTTPS time bootstrapper:

```bash
./install.sh --install-time-sync
```

It installs a systemd oneshot service that reads trusted HTTPS `Date` headers,
sets the system clock, and writes the hardware clock when possible.

This is a practical fallback for boards. A working NTP service is still the
preferred long-term fix.

### Proxies

If your network requires an HTTP or HTTPS proxy, export the standard proxy
variables before launching:

```bash
export HTTPS_PROXY=http://proxy.example.com:8080
export HTTP_PROXY=http://proxy.example.com:8080
claude-deepseek
```

## Updating

Pull the latest repository and rerun the installer:

```bash
git pull
./install.sh
```

On Windows:

```powershell
git pull
.\install.cmd
```

To change only the DeepSeek API key:

```bash
claude-deepseek-config
```

## Uninstall

Remove the launcher commands:

```bash
./uninstall.sh
```

Remove the saved API key too:

```bash
./uninstall.sh --purge-config
```

Remove the optional HTTPS time sync service:

```bash
./uninstall.sh --remove-time-sync
```

Claude Code itself is not removed by default. To remove it:

```bash
npm uninstall -g @anthropic-ai/claude-code
```

On Windows:

```powershell
.\uninstall.cmd
.\uninstall.cmd -PurgeConfig
```

## Troubleshooting

### `No DeepSeek API key configured`

Run:

```bash
claude-deepseek-config
```

Then start again:

```bash
claude-deepseek
```

### `node: not found` or Node.js is too old

On Linux, run:

```bash
./install.sh --install-node
```

On Windows, install Node.js 22 LTS from [nodejs.org](https://nodejs.org), then
rerun:

```powershell
.\install.cmd
```

### `exec: claude: not found`

`claude-deepseek` delegates to the native Claude Code command named `claude`.
Install Claude Code, then make sure npm's global binary directory is in `PATH`:

```bash
npm install -g @anthropic-ai/claude-code@2.1.153
command -v claude
claude-deepseek
```

If `npm` installed Claude Code but `command -v claude` prints nothing, add npm's
global bin directory to your shell profile and reload it:

```bash
NPM_PREFIX="$(npm config get prefix)"
echo 'export PATH="$(npm config get prefix)/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
command -v claude
```

On some boards, using the project installer is the easiest fix because it can
install Node.js and Claude Code together:

```bash
./install.sh --install-node
```

### `CERT_NOT_YET_VALID`

Your system clock is wrong. Fix NTP, or install the optional clock bootstrapper:

```bash
./install.sh --install-time-sync
```

### Native `claude` still uses Anthropic

That is expected. This project intentionally keeps:

```bash
claude
```

as the native Claude Code command, and uses:

```bash
claude-deepseek
```

for DeepSeek.

### Windows cannot find `claude-deepseek`

Open a new PowerShell or Command Prompt after running `install.cmd`. If it still
does not resolve, run:

```powershell
$env:Path += ";$env:LOCALAPPDATA\claude-deepseek\bin"
claude-deepseek --version
```

## References

- [DeepSeek: Claude Code integration](https://api-docs.deepseek.com/quick_start/agent_integrations/claude_code)
- [Claude Code environment variables](https://docs.anthropic.com/en/docs/claude-code/settings#environment-variables)
- [Node.js downloads](https://nodejs.org/en/download)

## License

MIT License. See [LICENSE](LICENSE).
