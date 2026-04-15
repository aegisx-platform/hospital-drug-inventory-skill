#!/usr/bin/env bash
# Remove the installed skill from a target.
#
# Usage:
#   ./scripts/uninstall.sh <target-project-dir>
#   ./scripts/uninstall.sh --user
#   ./scripts/uninstall.sh --desktop
set -euo pipefail

SKILL_NAME="hospital-drug-inventory"

if [[ $# -lt 1 ]]; then
  echo "usage: $0 <target-project-dir> | --user | --desktop" >&2
  exit 2
fi

case "$1" in
  --user)    DEST="$HOME/.claude/skills/$SKILL_NAME" ;;
  --desktop) DEST="$HOME/Library/Application Support/Claude/skills/user/$SKILL_NAME" ;;
  *)         DEST="$1/.claude/skills/$SKILL_NAME" ;;
esac

if [[ ! -d "$DEST" ]]; then
  echo "not installed: $DEST" >&2
  exit 0
fi

rm -rf "$DEST"
echo "uninstalled: $DEST"
