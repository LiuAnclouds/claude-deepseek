# Security Policy

## Reporting a Vulnerability

Please report security issues privately through the repository owner's preferred
GitHub contact channel. Do not open a public issue for secrets exposure,
credential handling bugs, or command injection concerns.

## Secret Handling

`claude-deepseek-config` stores the DeepSeek API key at:

```text
~/.config/claude-deepseek/env
```

The file is written with mode `600`, and the key is never printed back to the
terminal. Treat the file as a local secret and do not commit it to a repository.

## Scope

This project provides shell launchers and installers. It does not proxy,
inspect, or persist Claude Code conversations.
