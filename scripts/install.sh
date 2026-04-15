#!/usr/bin/env bash
# Install hospital-drug-inventory skill into a target project or user scope.
#
# Usage:
#   ./scripts/install.sh <target-project-dir>     # project scope: <dir>/.claude/skills/
#   ./scripts/install.sh --user                   # user scope:    ~/.claude/skills/
#   ./scripts/install.sh --desktop                # Claude Desktop: ~/Library/Application Support/Claude/skills/user/
set -euo pipefail

SKILL_NAME="hospital-drug-inventory"
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ $# -lt 1 ]]; then
  echo "usage: $0 <target-project-dir> | --user | --desktop" >&2
  exit 2
fi

case "$1" in
  --user)
    DEST="$HOME/.claude/skills/$SKILL_NAME"
    ;;
  --desktop)
    DEST="$HOME/Library/Application Support/Claude/skills/user/$SKILL_NAME"
    ;;
  *)
    DEST="$1/.claude/skills/$SKILL_NAME"
    ;;
esac

mkdir -p "$(dirname "$DEST")"
rm -rf "$DEST"
mkdir -p "$DEST"

# Copy skill payload only — exclude VCS, CI, install tooling, and dotfiles.
rsync -a \
  --exclude '.git' \
  --exclude '.gitignore' \
  --exclude '.github' \
  --exclude 'scripts/install.sh' \
  --exclude '*.bak' \
  --exclude '*.skill' \
  --exclude '.DS_Store' \
  "$SRC_DIR/" "$DEST/"

echo "installed: $DEST"
