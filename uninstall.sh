#!/usr/bin/env sh
set -eu

INSTALL_PREFIX="${INSTALL_PREFIX:-/usr/local}"
BIN_DIR="${BIN_DIR:-$INSTALL_PREFIX/bin}"
PURGE_CONFIG="0"
REMOVE_TIME_SYNC="0"

usage() {
  cat <<EOF
Usage:
  ./uninstall.sh [options]

Options:
  --purge-config      Remove ~/.config/claude-horizon
  --remove-time-sync  Disable and remove optional https-time-sync service
  -h, --help          Show this help
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --purge-config)
      PURGE_CONFIG="1"
      ;;
    --remove-time-sync)
      REMOVE_TIME_SYNC="1"
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage >&2
      exit 2
      ;;
  esac
  shift
done

as_root() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  elif command -v sudo >/dev/null 2>&1; then
    sudo "$@"
  else
    echo "root privileges are required; install sudo or run as root" >&2
    exit 1
  fi
}

as_root rm -f "$BIN_DIR/claude-horizon" "$BIN_DIR/claude-horizon-config" "$BIN_DIR/claude-horizon-models"
echo "Removed claude-horizon commands from $BIN_DIR"

if [ "$REMOVE_TIME_SYNC" = "1" ]; then
  if command -v systemctl >/dev/null 2>&1; then
    as_root systemctl disable --now https-time-sync.service >/dev/null 2>&1 || true
    as_root rm -f /etc/systemd/system/https-time-sync.service
    as_root systemctl daemon-reload
  fi
  as_root rm -f "$BIN_DIR/https-time-sync"
  echo "Removed https-time-sync"
fi

if [ "$PURGE_CONFIG" = "1" ]; then
  rm -rf "$HOME/.config/claude-horizon"
  echo "Removed $HOME/.config/claude-horizon"
fi

echo "Native Claude Code was not removed. To remove it, run: npm uninstall -g @anthropic-ai/claude-code"
