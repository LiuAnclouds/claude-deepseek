# Claude Horizon

<p align="center">
  <strong>Run Claude Code with Horizon's Anthropic-compatible API on Linux boards and Windows desktops.</strong>
</p>

<p align="center">
  <a href="#linux-quick-start"><img alt="Linux" src="https://img.shields.io/badge/Linux-supported-2ea44f?style=for-the-badge"></a>
  <a href="#windows-quick-start"><img alt="Windows" src="https://img.shields.io/badge/Windows-supported-0078d4?style=for-the-badge&logo=windows&logoColor=white"></a>
  <a href="#requirements"><img alt="Node.js 18+" src="https://img.shields.io/badge/Node.js-18%2B-43853d?style=for-the-badge&logo=node.js&logoColor=white"></a>
  <a href="https://api-docs.deepseek.com/quick_start/agent_integrations/claude_code"><img alt="Horizon" src="https://img.shields.io/badge/Horizon-Claude%20Code-0f172a?style=for-the-badge"></a>
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

`claude-horizon` is a small launcher that keeps the native `claude` command
intact and adds a dedicated Horizon-backed command:

```bash
claude            # native Anthropic Claude Code
claude-horizon    # Claude Code routed to Horizon
```

It follows the Anthropic-compatible API pattern by setting
`ANTHROPIC_BASE_URL` to the API endpoint and using Horizon's model lineup.

> Native Claude Code stays available as `claude`. Horizon-backed execution is
> always explicit through `claude-horizon`.

## Why

Linux development boards and Windows desktops often need a repeatable way to
bootstrap Claude Code without hand-editing shell profiles on every device. This
project packages the working pattern into installable commands:

<table>
  <tr>
    <td width="33%">
      <h3>Separate Command</h3>
      <p>Leaves <code>claude</code> untouched and adds <code>claude-horizon</code> for Horizon.</p>
    </td>
    <td width="33%">
      <h3>One-Time Key Setup</h3>
      <p>Stores the Horizon API key locally with user-only file permissions.</p>
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
git clone https://github.com/LiuAnclouds/claude-horizon.git
cd claude-horizon
chmod +x install.sh
./install.sh
```

Configure your Horizon API key once:

```bash
claude-horizon-config
```

Start Claude Code through Horizon:

```bash
claude-horizon
```

The first run should open the normal Claude Code interface, but API requests go
to Horizon's Anthropic-compatible endpoint.

## Linux One-Line Install

For fresh boards:

```bash
curl -fsSL https://raw.githubusercontent.com/LiuAnclouds/claude-horizon/main/install.sh | sh
```

If the board has a bad system clock and TLS certificates fail, use the full
clone flow and install the optional HTTPS time sync service:

```bash
git clone https://github.com/LiuAnclouds/claude-horizon.git
cd claude-horizon
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
| Network | The board must be able to reach `llmapi.horizon.auto` over HTTPS. |

## What It Installs

The installer adds two commands under `/usr/local/bin` by default:

| Command | Purpose |
| --- | --- |
| `claude-horizon` | Launch Claude Code with Horizon endpoint and model environment variables. |
| `claude-horizon-config` | Save, show, or remove the Horizon API key. |

It also installs Claude Code when needed:

```bash
npm install -g @anthropic-ai/claude-code@2.1.153
```

The native `claude` command is intentionally left alone.

## Default Model

`claude-horizon` maps two models to Claude Code's role slots:

```bash
ANTHROPIC_BASE_URL=https://llmapi.horizon.auto
ANTHROPIC_MODEL=HORIZON-DeepSeek-Pro
ANTHROPIC_DEFAULT_OPUS_MODEL=HORIZON-DeepSeek-Pro
ANTHROPIC_DEFAULT_SONNET_MODEL=HORIZON-GLM
ANTHROPIC_DEFAULT_HAIKU_MODEL=HORIZON-DeepSeek-Pro
CLAUDE_CODE_SUBAGENT_MODEL=HORIZON-GLM
CLAUDE_CODE_EFFORT_LEVEL=max
```

Use `claude-horizon-models` to reassign individual roles:

```bash
claude-horizon-models --list                  # show current assignments
claude-horizon-models --set sonnet HORIZON-DeepSeek-Pro
claude-horizon-models --reset                 # back to defaults
```

You can also override any value for a single run:

```bash
ANTHROPIC_MODEL='HORIZON-GLM' claude-horizon
```

## API Key Management

Save or replace your key:

```bash
claude-horizon-config
```

Check whether a key is configured:

```bash
claude-horizon-config --show
```

Print the config path:

```bash
claude-horizon-config --path
```

Remove the saved key:

```bash
claude-horizon-config --unset
```

The key is stored at:

```text
~/.config/claude-horizon/env
```

The directory is created with mode `700`, and the key file is written with mode
`600`. The command never prints the saved key back to the terminal.

For CI or temporary sessions, you can skip saved config:

```bash
DEEPSEEK_API_KEY='sk-...' claude-horizon --print 'hello'
```

or:

```bash
ANTHROPIC_AUTH_TOKEN='sk-...' claude-horizon --print 'hello'
```

## Windows Quick Start

Install from PowerShell:

```powershell
git clone https://github.com/LiuAnclouds/claude-horizon.git
cd claude-horizon
.\install.cmd
```

`install.cmd` launches the PowerShell installer with `-ExecutionPolicy Bypass`,
so it works on machines where local `.ps1` scripts are restricted.

PowerShell users can also call the installer directly:

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

Configure your Horizon API key once:

```powershell
claude-horizon-config
```

Start Claude Code through Horizon:

```powershell
claude-horizon
```

The Windows installer adds `%LOCALAPPDATA%\claude-horizon\bin` to the user
PATH. Open a new terminal after installation if the command is not immediately
available in the current session.

Only `.cmd` shims are placed in the PATH directory. The PowerShell scripts live
under `%LOCALAPPDATA%\claude-horizon\libexec` and are launched with
`-ExecutionPolicy Bypass`, so normal `claude-horizon` usage is not blocked by a
restricted PowerShell execution policy.

Windows keeps the native `claude` command untouched. `claude-horizon` is the
Horizon-backed entry point.

### Windows API Key Location

The saved key lives at:

```text
%USERPROFILE%\.config\claude-horizon\env
```

To remove it:

```powershell
claude-horizon-config -Unset
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
| `--skip-claude-code` | Only install the Horizon launcher/config commands. |
| `--install-time-sync` | Install optional HTTPS Date-header clock bootstrap service. |

Windows:

```powershell
.\install.cmd [-ClaudeCodeVersion 2.1.153] [-SkipClaudeCode] [-NoPath]
```

| Parameter | Description |
| --- | --- |
| `-ClaudeCodeVersion` | Claude Code npm version to install. Default: `2.1.153`. |
| `-InstallDir` | User install directory. Default: `%LOCALAPPDATA%\claude-horizon`. |
| `-SkipClaudeCode` | Only install the Horizon launcher/config commands. |
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
claude-horizon
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

To change only the Horizon API key:

```bash
claude-horizon-config
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

### `No Horizon API key configured`

Run:

```bash
claude-horizon-config
```

Then start again:

```bash
claude-horizon
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
claude-horizon
```

for Horizon.

### Windows cannot find `claude-horizon`

Open a new PowerShell or Command Prompt after running `install.cmd`. If it still
does not resolve, run:

```powershell
$env:Path += ";$env:LOCALAPPDATA\claude-horizon\bin"
claude-horizon --version
```

## References

- [DeepSeek: Claude Code integration](https://api-docs.deepseek.com/quick_start/agent_integrations/claude_code)
- [Claude Code environment variables](https://docs.anthropic.com/en/docs/claude-code/settings#environment-variables)
- [Node.js downloads](https://nodejs.org/en/download)

## License

MIT License. See [LICENSE](LICENSE).
