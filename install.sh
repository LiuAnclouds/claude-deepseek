#!/usr/bin/env sh
set -eu

PROJECT_NAME="claude-deepseek"
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
REPO_RAW_BASE="${REPO_RAW_BASE:-https://raw.githubusercontent.com/LiuAnclouds/claude-deepseek/main}"
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
    ensure_claude_on_path
    return
  fi

  need_cmd npm
  npm_bin=$(command -v npm)
  log "Installing @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION} (pinned; auto-update disabled)"
  as_root "$npm_bin" install -g "@anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}"

  ensure_claude_on_path
  disable_claude_autoupdate
}

# Some npm setups install the `claude` shim into a prefix that is not on the
# default PATH (e.g. ~/.npm-global/bin, /opt/node-*/bin). If `claude` is not
# discoverable after the npm install, symlink it into $BIN_DIR so the
# claude-deepseek launcher can always find it.
ensure_claude_on_path() {
  if command -v claude >/dev/null 2>&1; then
    log "claude command available at: $(command -v claude)"
    return
  fi

  candidate=""
  if command -v npm >/dev/null 2>&1; then
    npm_prefix=$(npm prefix -g 2>/dev/null || true)
    if [ -n "$npm_prefix" ] && [ -x "$npm_prefix/bin/claude" ]; then
      candidate="$npm_prefix/bin/claude"
    fi
  fi

  if [ -z "$candidate" ]; then
    for guess in \
      "$INSTALL_PREFIX/bin/claude" \
      "$HOME/.npm-global/bin/claude" \
      "/usr/lib/node_modules/@anthropic-ai/claude-code/cli.js" \
      "/usr/local/lib/node_modules/@anthropic-ai/claude-code/cli.js"
    do
      if [ -x "$guess" ]; then
        candidate="$guess"
        break
      fi
    done
  fi

  if [ -z "$candidate" ]; then
    log "warning: could not locate the claude binary. Run 'npm root -g' and add its bin dir to PATH."
    return
  fi

  as_root mkdir -p "$BIN_DIR"
  as_root ln -sfn "$candidate" "$BIN_DIR/claude"
  log "Linked claude -> $candidate at $BIN_DIR/claude"
}

# Disable the Claude Code built-in auto-updater so the pinned version stays
# put. We touch both the installing user's config and root's (if we used sudo
# during npm install) because Claude Code reads whichever HOME it runs under.
disable_claude_autoupdate() {
  set_autoupdate_false "$HOME/.claude.json" ""

  if [ "$(id -u)" -ne 0 ] && command -v sudo >/dev/null 2>&1; then
    root_home=$(getent passwd root 2>/dev/null | awk -F: '{print $6}')
    [ -n "$root_home" ] || root_home="/root"
    set_autoupdate_false "$root_home/.claude.json" "as_root"
  fi
}

# Args: $1 = target path, $2 = "as_root" to run privileged
set_autoupdate_false() {
  target="$1"
  privileged="${2:-}"

  if [ -f "$target" ]; then
    if command -v node >/dev/null 2>&1; then
      if [ "$privileged" = "as_root" ]; then
        as_root node -e 'const fs=require("fs"),p=process.argv[1];let d={};try{d=JSON.parse(fs.readFileSync(p,"utf8"))}catch(_){}d.autoUpdates=false;fs.writeFileSync(p,JSON.stringify(d,null,2)+"\n");' "$target"
      else
        node -e 'const fs=require("fs"),p=process.argv[1];let d={};try{d=JSON.parse(fs.readFileSync(p,"utf8"))}catch(_){}d.autoUpdates=false;fs.writeFileSync(p,JSON.stringify(d,null,2)+"\n");' "$target"
      fi
      log "Set autoUpdates=false in $target"
    else
      log "warning: node missing; cannot patch $target. Set \"autoUpdates\": false manually."
    fi
  else
    dir=$(dirname "$target")
    if [ "$privileged" = "as_root" ]; then
      as_root mkdir -p "$dir"
      printf '{\n  "autoUpdates": false\n}\n' | as_root tee "$target" >/dev/null
      as_root chmod 600 "$target" >/dev/null 2>&1 || true
    else
      mkdir -p "$dir"
      printf '{\n  "autoUpdates": false\n}\n' > "$target"
      chmod 600 "$target" >/dev/null 2>&1 || true
    fi
    log "Wrote autoUpdates=false to new $target"
  fi
}

install_commands() {
  as_root mkdir -p "$BIN_DIR"
  as_root install -m 0755 "$SOURCE_DIR/bin/claude-deepseek" "$BIN_DIR/claude-deepseek"
  as_root install -m 0755 "$SOURCE_DIR/bin/claude-deepseek-config" "$BIN_DIR/claude-deepseek-config"
  log "Installed claude-deepseek commands to $BIN_DIR"
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
  if [ -f "$SOURCE_DIR/bin/claude-deepseek" ] && [ -f "$SOURCE_DIR/bin/claude-deepseek-config" ]; then
    return
  fi

  need_cmd curl
  tmp_dir=$(make_temp_dir)
  mkdir -p "$tmp_dir/bin" "$tmp_dir/extras"

  log "Source files not found next to install.sh; downloading from $REPO_RAW_BASE"
  for file in \
    bin/claude-deepseek \
    bin/claude-deepseek-config \
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
  log "Next: run claude-deepseek-config, then claude-deepseek"
}

main "$@"
