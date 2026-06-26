# Architecture

Claude Horizon is intentionally small:

```text
claude-horizon
  -> loads ~/.config/claude-horizon/env when present
  -> loads ~/.config/claude-horizon/models when present
  -> exports Horizon Anthropic-compatible endpoint variables
  -> execs native Claude Code
```

The wrapper does not modify `claude`, does not patch Claude Code, and does not
store conversations.

## Components

| File | Role |
| --- | --- |
| `bin/claude-horizon` | Runtime launcher. |
| `bin/claude-horizon-config` | One-time API key configuration helper. |
| `bin/claude-horizon-models` | Manage models shown by /model command. |
| `bin/windows/claude-horizon.ps1` | Windows runtime launcher. |
| `bin/windows/claude-horizon-config.ps1` | Windows one-time API key configuration helper. |
| `bin/windows/claude-horizon-models.ps1` | Windows model management helper. |
| `install.sh` | Board bootstrapper for Node.js, Claude Code, and commands. |
| `install.ps1` | Windows user-space installer for Claude Code and command shims. |
| `extras/https-time-sync` | Optional clock bootstrap fallback for boards without NTP. |
| `uninstall.sh` | Removes launcher commands and optional local config. |
| `uninstall.ps1` | Removes Windows launcher commands and optional local config. |
