#!/usr/bin/env sh
set -eu

PROJECT_NAME="claude-horizon"
CLAUDE_CODE_VERSION="${CLAUDE_CODE_VERSION:-2.1.153}"
NODE_MAJOR="${NODE_MAJOR:-22}"
INSTALL_PREFIX="${INSTALL_PREFIX:-/usr/local}"
BIN_DIR="${BIN_DIR:-$INSTALL_PREFIX/bin}"
NODE_INSTALL_ROOT="${NODE_INSTALL_ROOT:-/opt}"
INSTALL_NODE="auto"
INSTALL_TIME_SYNC="0"
SKIP_CLAUDE_CODE="0"

log() {
  printf '%s\n' "[$PROJECT_NAME] $*"
}

die() {
  printf '%s\n' "[$PROJECT_NAME] error: $*" >&2
  exit 1
}

usage() {
  cat <<EOF
Usage:
  ./install.sh [options]

Options:
  --install-node       Install official Node.js ${NODE_MAJOR}.x even when node exists
  --no-install-node    Do not install Node.js automatically
  --skip-claude-code   Do not install @anthropic-ai/claude-code
  --install-time-sync  Install optional HTTPS time sync systemd service
  -h, --help           Show this help

Environment:
  CLAUDE_CODE_VERSION  Claude Code npm version to install (default: ${CLAUDE_CODE_VERSION})
  NODE_MAJOR           Node.js major line for auto-install (default: ${NODE_MAJOR})
  INSTALL_PREFIX       Install prefix for commands (default: ${INSTALL_PREFIX})
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --install-node)
      INSTALL_NODE="yes"
      ;;
    --no-install-node)
      INSTALL_NODE="no"
      ;;
    --skip-claude-code)
      SKIP_CLAUDE_CODE="1"
      ;;
    --install-time-sync)
      INSTALL_TIME_SYNC="1"
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage >&2
      die "unknown option: $1"
      ;;
  esac
  shift
done

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
SOURCE_DIR="$SCRIPT_DIR"
REPO_RAW_BASE="${REPO_RAW_BASE:-https://raw.githubusercontent.com/LiuAnclouds/claude-horizon/main}"
TEMP_DIRS=""

cleanup() {
  for dir in $TEMP_DIRS; do
    rm -rf "$dir"
  done
}

trap cleanup EXIT INT TERM

make_temp_dir() {
  dir=$(mktemp -d)
  TEMP_DIRS="$TEMP_DIRS $dir"
  printf '%s\n' "$dir"
}

as_root() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  elif command -v sudo >/dev/null 2>&1; then
    sudo "$@"
  else
    die "root privileges are required; install sudo or run as root"
  fi
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"
}

node_major_ok() {
  command -v node >/dev/null 2>&1 || return 1
  node -e 'process.exit(Number(process.versions.node.split(".")[0]) >= 18 ? 0 : 1)' >/dev/null 2>&1
}

node_platform() {
  arch=$(uname -m)
  case "$arch" in
    x86_64|amd64)
      printf '%s\n' "linux-x64"
      ;;
    aarch64|arm64)
      printf '%s\n' "linux-arm64"
      ;;
    armv7l)
      printf '%s\n' "linux-armv7l"
      ;;
    *)
      die "unsupported CPU architecture for automatic Node.js install: $arch"
      ;;
  esac
}

install_node_official() {
  need_cmd curl
  need_cmd tar
  need_cmd sha256sum

  platform=$(node_platform)
  tmp_dir=$(make_temp_dir)

  base_url="https://nodejs.org/dist/latest-v${NODE_MAJOR}.x"
  shasums="$tmp_dir/SHASUMS256.txt"
  log "Downloading Node.js ${NODE_MAJOR}.x metadata for $platform"
  curl -fsSL "$base_url/SHASUMS256.txt" -o "$shasums"

  archive=$(awk '{print $2}' "$shasums" | grep "node-v.*-${platform}\.tar\.xz$" | head -n 1)
  [ -n "$archive" ] || die "could not find Node.js archive for $platform"

  archive_path="$tmp_dir/$archive"
  log "Downloading $archive"
  curl -fL "$base_url/$archive" -o "$archive_path"

  log "Verifying SHA256"
  (cd "$tmp_dir" && grep " $archive$" "$shasums" | sha256sum -c -)

  install_name=$(printf '%s\n' "$archive" | sed 's/\.tar\.xz$//')
  install_dir="$NODE_INSTALL_ROOT/$install_name"
  log "Installing Node.js to $install_dir"
  as_root mkdir -p "$NODE_INSTALL_ROOT"
  as_root tar -xJf "$archive_path" -C "$NODE_INSTALL_ROOT"
  as_root mkdir -p "$BIN_DIR"

  for bin in node npm npx corepack; do
    if [ -x "$install_dir/bin/$bin" ]; then
      as_root ln -sfn "$install_dir/bin/$bin" "$BIN_DIR/$bin"
    fi
  done
}

ensure_node() {
  if [ "$INSTALL_NODE" = "yes" ]; then
    install_node_official
    return
  fi

  if node_major_ok; then
    log "Node.js is already >= 18: $(node -v)"
    return
  fi

  if [ "$INSTALL_NODE" = "no" ]; then
    die "Node.js >= 18 is required; rerun without --no-install-node or install Node manually"
  fi

  log "Node.js >= 18 not found; installing official Node.js ${NODE_MAJOR}.x"
  install_node_official
}

install_claude_code() {
  if [ "$SKIP_CLAUDE_CODE" = "1" ]; then
    log "Skipping Claude Code installation"
    return
  fi

  need_cmd npm
  npm_bin=$(command -v npm)
  log "Installing @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}"
  as_root "$npm_bin" install -g "@anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}"
}

install_commands() {
  as_root mkdir -p "$BIN_DIR"
  as_root install -m 0755 "$SOURCE_DIR/bin/claude-horizon" "$BIN_DIR/claude-horizon"
  as_root install -m 0755 "$SOURCE_DIR/bin/claude-horizon-config" "$BIN_DIR/claude-horizon-config"
  as_root install -m 0755 "$SOURCE_DIR/bin/claude-horizon-models" "$BIN_DIR/claude-horizon-models"
  log "Installed claude-horizon commands to $BIN_DIR"
}

install_time_sync() {
  if [ "$INSTALL_TIME_SYNC" != "1" ]; then
    return 0
  fi

  [ -f "$SOURCE_DIR/extras/https-time-sync" ] || die "missing extras/https-time-sync"
  [ -f "$SOURCE_DIR/extras/https-time-sync.service" ] || die "missing extras/https-time-sync.service"

  as_root install -m 0755 "$SOURCE_DIR/extras/https-time-sync" "$BIN_DIR/https-time-sync"

  if command -v systemctl >/dev/null 2>&1; then
    tmp_service=$(mktemp)
    sed "s|@BIN_DIR@|$BIN_DIR|g" "$SOURCE_DIR/extras/https-time-sync.service" > "$tmp_service"
    as_root install -m 0644 "$tmp_service" /etc/systemd/system/https-time-sync.service
    rm -f "$tmp_service"
    as_root systemctl daemon-reload
    as_root systemctl enable https-time-sync.service
    log "Installed and enabled https-time-sync.service"
  else
    log "systemctl not found; installed https-time-sync command only"
  fi
}

prepare_source_files() {
  if [ -f "$SOURCE_DIR/bin/claude-horizon" ] && [ -f "$SOURCE_DIR/bin/claude-horizon-config" ] && [ -f "$SOURCE_DIR/bin/claude-horizon-models" ]; then
    return
  fi

  need_cmd curl
  tmp_dir=$(make_temp_dir)
  mkdir -p "$tmp_dir/bin" "$tmp_dir/extras"

  log "Source files not found next to install.sh; downloading from $REPO_RAW_BASE"
  for file in \
    bin/claude-horizon \
    bin/claude-horizon-config \
    bin/claude-horizon-models \
    extras/https-time-sync \
    extras/https-time-sync.service
  do
    curl -fsSL "$REPO_RAW_BASE/$file" -o "$tmp_dir/$file"
  done

  SOURCE_DIR="$tmp_dir"
}

main() {
  [ "$(uname -s)" = "Linux" ] || die "this installer supports Linux only"
  need_cmd sed
  need_cmd awk

  prepare_source_files
  ensure_node
  install_claude_code
  install_commands
  install_time_sync

  log "Done"
  log "Next: run claude-horizon-config, then claude-horizon"
}

main "$@"
