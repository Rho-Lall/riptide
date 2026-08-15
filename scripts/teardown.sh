#!/bin/bash
# teardown.sh — Remove all Riptide artifacts from a target project
# Usage: teardown.sh {target-project-path}
# Leaves all project source code untouched.

set -euo pipefail

# --- Validate arguments ---
if [ -z "${1:-}" ]; then
  echo "Usage: teardown.sh <target-project-path>"
  echo "Error: target project path is required."
  exit 1
fi

TARGET="$(cd "$1" 2>/dev/null && pwd)" || {
  echo "Error: target path '$1' does not exist or is not a directory."
  exit 1
}

echo "Removing Riptide artifacts from: $TARGET"

# --- Remove .claude/ directory ---
if [ -d "$TARGET/.claude" ]; then
  rm -rf "$TARGET/.claude"
  echo "  ✓ Removed .claude/"
else
  echo "  - .claude/ not found (skipped)"
fi

# --- Remove CLAUDE.md ---
if [ -f "$TARGET/CLAUDE.md" ]; then
  rm -f "$TARGET/CLAUDE.md"
  echo "  ✓ Removed CLAUDE.md"
else
  echo "  - CLAUDE.md not found (skipped)"
fi

# --- Remove RIPTIDE.md ---
if [ -f "$TARGET/RIPTIDE.md" ]; then
  rm -f "$TARGET/RIPTIDE.md"
  echo "  ✓ Removed RIPTIDE.md"
else
  echo "  - RIPTIDE.md not found (skipped)"
fi

# --- Remove .riptide/ directory ---
if [ -d "$TARGET/.riptide" ]; then
  rm -rf "$TARGET/.riptide"
  echo "  ✓ Removed .riptide/"
else
  echo "  - .riptide/ not found (skipped)"
fi

# --- Remove docs/TECH_SPEC.md ---
if [ -f "$TARGET/docs/TECH_SPEC.md" ]; then
  rm -f "$TARGET/docs/TECH_SPEC.md"
  echo "  ✓ Removed docs/TECH_SPEC.md"
else
  echo "  - docs/TECH_SPEC.md not found (skipped)"
fi

# --- Remove docs/BAR.md ---
if [ -f "$TARGET/docs/BAR.md" ]; then
  rm -f "$TARGET/docs/BAR.md"
  echo "  ✓ Removed docs/BAR.md"
else
  echo "  - docs/BAR.md not found (skipped)"
fi

# --- Remove docs/CHANNELS.md ---
if [ -f "$TARGET/docs/CHANNELS.md" ]; then
  rm -f "$TARGET/docs/CHANNELS.md"
  echo "  ✓ Removed docs/CHANNELS.md"
else
  echo "  - docs/CHANNELS.md not found (skipped)"
fi

# --- Remove docs/solutions/ ---
if [ -d "$TARGET/docs/solutions" ]; then
  rm -rf "$TARGET/docs/solutions"
  echo "  ✓ Removed docs/solutions/"
else
  echo "  - docs/solutions/ not found (skipped)"
fi

# --- Remove dashboard/ ---
if [ -d "$TARGET/dashboard" ]; then
  rm -rf "$TARGET/dashboard"
  echo "  ✓ Removed dashboard/"
else
  echo "  - dashboard/ not found (skipped)"
fi

echo ""
echo "Done. Riptide artifacts removed from $TARGET"
echo "Project source code is untouched."
