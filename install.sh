#!/bin/sh

set -eu

REPO="${SHADER_REPO:-yuleshow/rg34xx-knulli-shaders}"
BRANCH="${SHADER_BRANCH:-}"
INSTALL_DIR="${SHADERS_DIR:-}"
DRY_RUN=0

usage()
{
  cat <<EOF
Usage: sh install.sh [options]

Options:
  --dir PATH       Install into PATH.
  --repo OWNER/REPO Override the GitHub repository.
  --branch NAME    Use a repository branch instead of auto-detecting main/master.
  --dry-run        Show what would be installed.
  -h, --help       Show this help.

Environment:
  SHADERS_DIR      Installation directory.
  SHADER_REPO      GitHub repository in owner/repo form.
  SHADER_BRANCH    GitHub branch name.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --dir)
      [ "$#" -ge 2 ] || { echo "Missing value for --dir" >&2; exit 2; }
      INSTALL_DIR="$2"
      shift 2
      ;;
    --repo)
      [ "$#" -ge 2 ] || { echo "Missing value for --repo" >&2; exit 2; }
      REPO="$2"
      shift 2
      ;;
    --branch)
      [ "$#" -ge 2 ] || { echo "Missing value for --branch" >&2; exit 2; }
      BRANCH="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if ! command -v curl >/dev/null 2>&1; then
  echo "curl is required." >&2
  exit 1
fi

FILES="rg34xx_crt.glsl
rg34xx_gba_granular.glsl
rg34xx_nes.glslp
rg34xx_snes.glslp
rg34xx_gba_granular.glslp
rg34xx_gb.glslp
rg34xx_gbc.glslp
rg34xx_pc_engine.glslp
rg34xx_pc_engine_cd.glslp"

CONFIG_FILE="rendering-defaults.yml"

if [ -z "$INSTALL_DIR" ]; then
  if [ -d "/Volumes/share" ]; then
    INSTALL_DIR="/Volumes/share/shaders"
  else
    for candidate in \
      /userdata/shaders \
      /userdata/system/configs/retroarch/shaders \
      "$HOME/.config/retroarch/shaders"
    do
      if [ -d "$candidate" ]; then
        INSTALL_DIR="$candidate"
        break
      fi
    done
  fi
fi

if [ -z "$INSTALL_DIR" ]; then
  INSTALL_DIR="/userdata/shaders"
fi

case "$INSTALL_DIR" in
  */yuleshow-rg34xx|*/yuleshow-rg34xx/)
    INSTALL_DIR="${INSTALL_DIR%/}"
    ;;
  /Volumes/share)
    INSTALL_DIR="/Volumes/share/shaders/yuleshow-rg34xx"
    ;;
  *)
    INSTALL_DIR="${INSTALL_DIR%/}/yuleshow-rg34xx"
    ;;
esac

if [ "$DRY_RUN" -eq 1 ]; then
  echo "Repository: $REPO"
  echo "Installation directory: $INSTALL_DIR"
  printf "Files:\n%s\n" "$FILES"
  exit 0
fi

if [ ! -d "$INSTALL_DIR" ]; then
  mkdir -p "$INSTALL_DIR" || {
    echo "Cannot create installation directory: $INSTALL_DIR" >&2
    exit 1
  }
fi

detect_branch()
{
  if [ -n "$BRANCH" ]; then
    printf '%s' "$BRANCH"
    return
  fi

  if curl -fsSL "https://raw.githubusercontent.com/$REPO/main/rg34xx_crt.glsl" -o /dev/null; then
    printf '%s' "main"
  elif curl -fsSL "https://raw.githubusercontent.com/$REPO/master/rg34xx_crt.glsl" -o /dev/null; then
    printf '%s' "master"
  else
    echo "Could not find rg34xx_crt.glsl in $REPO on main or master." >&2
    exit 1
  fi
}

BRANCH="$(detect_branch)"
BASE_URL="https://raw.githubusercontent.com/$REPO/$BRANCH"
TEMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/rg34xx-shaders.XXXXXX")"
trap 'rm -rf "$TEMP_DIR"' EXIT HUP INT TERM

printf 'Downloading RG34XX shaders from %s (%s)...\n' "$REPO" "$BRANCH"
for file in $FILES "$CONFIG_FILE"; do
  if ! curl -fL --retry 3 "$BASE_URL/$file" -o "$TEMP_DIR/$file"; then
    echo "Failed to download $file." >&2
    exit 1
  fi
done

for file in $FILES; do
  cat "$TEMP_DIR/$file" > "$INSTALL_DIR/$file" || {
    echo "Failed to install $file to $INSTALL_DIR." >&2
    exit 1
  }
done

SHADER_ROOT="${INSTALL_DIR%/yuleshow-rg34xx}"
CONFIG_DIR="$SHADER_ROOT/configs/yuleshow-rg34xx"
if [ ! -d "$CONFIG_DIR" ]; then
  mkdir -p "$CONFIG_DIR" || {
    echo "Cannot create configuration directory: $CONFIG_DIR" >&2
    exit 1
  }
fi
cat "$TEMP_DIR/$CONFIG_FILE" > "$CONFIG_DIR/$CONFIG_FILE" || {
  echo "Failed to install $CONFIG_FILE to $CONFIG_DIR." >&2
  exit 1
}
printf 'Installed %s shader files in %s\n' "$(printf '%s\n' "$FILES" | wc -l | tr -d ' ')" "$INSTALL_DIR"
