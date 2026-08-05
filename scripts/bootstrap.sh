#!/bin/bash
# bootstrap.sh — Deploy Riptide template into a target project
# Usage: bootstrap.sh {target-project-path}
# Idempotent: safe to run multiple times without error or duplication.
# Does NOT use symlinks (copies only).

set -euo pipefail

# --- Validate arguments ---
if [ -z "${1:-}" ]; then
  echo "Usage: bootstrap.sh <target-project-path>"
  echo "Error: target project path is required."
  exit 1
fi

TARGET="$(cd "$1" 2>/dev/null && pwd)" || {
  echo "Error: target path '$1' does not exist or is not a directory."
  exit 1
}

# --- Resolve template path relative to this script ---
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEMPLATE_DIR="$SCRIPT_DIR/../template"

if [ ! -d "$TEMPLATE_DIR" ]; then
  echo "Error: template directory not found at $TEMPLATE_DIR"
  exit 1
fi

echo "Deploying Riptide into: $TARGET"

# --- Detect single-repo vs multi-repo mode ---
# single-repo: $TARGET is itself a git working tree — waves use worktree isolation
#   (`git worktree add .worktrees/wave-x`), MODULE_MAP owns bare path globs.
# multi-repo: $TARGET is a workspace containing multiple independent repos (or isn't a
#   git repo at all) — waves cd into whichever repo(s) they touch and branch normally
#   there, MODULE_MAP owns `{repo}/{path-glob}` entries instead.
if git -C "$TARGET" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  MODE="single-repo"
else
  MODE="multi-repo"
fi
echo "  Detected mode: $MODE"

# --- Copy template contents (preserving directory structure) ---
# Uses cp -R without -P (no symlinks). Overwrites existing files (idempotent).
cp -R "$TEMPLATE_DIR"/ "$TARGET"/

echo "  ✓ Template files copied"

# --- Ensure .riptide/plans/ exists ---
mkdir -p "$TARGET/.riptide/plans"
echo "  ✓ .riptide/plans/ directory ready"

# --- Ensure docs/solutions/ exists ---
mkdir -p "$TARGET/docs/solutions"
echo "  ✓ docs/solutions/ directory ready"

# --- Initialize .riptide/status.json if not already present ---
STATUS_FILE="$TARGET/.riptide/status.json"
if [ ! -f "$STATUS_FILE" ]; then
  cat > "$STATUS_FILE" << EOF
{
  "mode": "$MODE",
  "tide": "",
  "waves": [],
  "solutions": [],
  "frozen": []
}
EOF
  echo "  ✓ .riptide/status.json initialized ($MODE)"
else
  echo "  ✓ .riptide/status.json already exists (skipped)"
fi

# --- Add .riptide/ to .gitignore if not already there ---
# Only meaningful in single-repo mode — a .gitignore at a multi-repo workspace root isn't
# tracked by any repo, so writing one there wouldn't actually ignore anything. Each member
# repo should ignore .riptide/ itself if it ever tracks files under the workspace root.
if [ "$MODE" = "single-repo" ]; then
  GITIGNORE="$TARGET/.gitignore"
  if [ ! -f "$GITIGNORE" ]; then
    echo ".riptide/" > "$GITIGNORE"
    echo "  ✓ Created .gitignore with .riptide/ entry"
  elif ! grep -qxF ".riptide/" "$GITIGNORE"; then
    echo "" >> "$GITIGNORE"
    echo ".riptide/" >> "$GITIGNORE"
    echo "  ✓ Added .riptide/ to .gitignore"
  else
    echo "  ✓ .riptide/ already in .gitignore (skipped)"
  fi
else
  echo "  ⓘ multi-repo mode: skipped root .gitignore (not tracked by any repo) — add .riptide/ to each member repo's own .gitignore if needed"
fi

echo ""
echo "Done. Riptide deployed to $TARGET"
