# Architecture

Claude DeepSeek is intentionally small:

```text
claude-deepseek
  -> loads ~/.config/claude-deepseek/env when present
  -> exports DeepSeek Anthropic-compatible endpoint variables
  -> execs native Claude Code
```

The wrapper does not modify `claude`, does not patch Claude Code, and does not
store conversations.

## Components

| File | Role |
| --- | --- |
| `bin/claude-deepseek` | Runtime launcher. |
| `bin/claude-deepseek-config` | One-time API key configuration helper. |
| `install.sh` | Board bootstrapper for Node.js, Claude Code, and commands. |
| `extras/https-time-sync` | Optional clock bootstrap fallback for boards without NTP. |
| `uninstall.sh` | Removes launcher commands and optional local config. |
