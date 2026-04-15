#!/usr/bin/env bash
# Validate the skill package structure before publishing / installing.
# Exits non-zero on any failure. Safe to run in CI.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
errors=0
warn() { echo "WARN: $*" >&2; }
fail() { echo "FAIL: $*" >&2; errors=$((errors+1)); }
ok()   { echo "OK:   $*"; }

# 1. SKILL.md exists with frontmatter containing name + description
if [[ ! -f SKILL.md ]]; then
  fail "SKILL.md missing"
else
  head -1 SKILL.md | grep -q '^---$' || fail "SKILL.md: missing frontmatter opening ---"
  awk '/^---$/{c++; next} c==1' SKILL.md | grep -qE '^name:[[:space:]]*[a-z0-9-]+' \
    || fail "SKILL.md: frontmatter missing 'name:' (lowercase-hyphen)"
  awk '/^---$/{c++; next} c==1' SKILL.md | grep -qE '^description:' \
    || fail "SKILL.md: frontmatter missing 'description:'"
  awk '/^---$/{c++; next} c==1' SKILL.md | grep -qE '^version:[[:space:]]*[0-9]+\.[0-9]+\.[0-9]+' \
    || warn "SKILL.md: frontmatter missing semver 'version:'"
  ok "SKILL.md frontmatter"
fi

# 2. Size check — SKILL.md should stay small for fast activation
size=$(wc -c < SKILL.md | tr -d ' ')
if (( size > 6000 )); then
  warn "SKILL.md is ${size} bytes (>6000). Consider moving detail to references/."
else
  ok "SKILL.md size ${size} bytes"
fi

# 3. References in SKILL.md router must exist
missing=0
while IFS= read -r ref; do
  [[ -z "$ref" ]] && continue
  if [[ ! -f "$ref" ]]; then
    fail "broken reference in SKILL.md: $ref"
    missing=$((missing+1))
  fi
done < <(grep -oE '`references/[a-zA-Z0-9_-]+\.md`' SKILL.md | tr -d '`' | sort -u)
(( missing == 0 )) && ok "reference links resolve"

# 4. No junk files
junk=$(find . -type f \( -name '.DS_Store' -o -name '*.bak' -o -name '*.skill' \) -not -path './.git/*' || true)
if [[ -n "$junk" ]]; then
  fail "junk files present:"
  echo "$junk" >&2
else
  ok "no junk files"
fi

# 5. install.sh is executable
if [[ -f scripts/install.sh ]]; then
  [[ -x scripts/install.sh ]] || fail "scripts/install.sh is not executable"
  ok "installer executable"
fi

if (( errors > 0 )); then
  echo "" >&2
  echo "validation failed with ${errors} error(s)" >&2
  exit 1
fi
echo ""
echo "validation passed"
