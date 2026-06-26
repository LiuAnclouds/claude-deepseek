# Contributing

Thanks for helping improve Claude Horizon.

## Development Principles

- Keep the native `claude` command untouched.
- Keep secrets out of shell history and repository files.
- Prefer POSIX-compatible shell for board compatibility.
- Keep installer behavior explicit and reversible.
- Test on at least one low-power Linux board or container before proposing
  installer changes.

## Local Checks

Run syntax checks:

```bash
sh -n install.sh
sh -n uninstall.sh
sh -n bin/claude-horizon
sh -n bin/claude-horizon-config
sh -n bin/claude-horizon-models
sh -n extras/https-time-sync
powershell -NoProfile -Command "Get-ChildItem *.ps1,bin/windows/*.ps1 | ForEach-Object { $null = [scriptblock]::Create((Get-Content $_ -Raw)) }"
```

If `shellcheck` is available:

```bash
shellcheck install.sh uninstall.sh bin/* extras/https-time-sync
```

## Pull Requests

Please include:

- What changed
- Why it changed
- How it was tested
- Any board/OS details relevant to the change
