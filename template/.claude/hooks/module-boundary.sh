#!/bin/bash
# module-boundary.sh
# Trigger: PreToolUse on Write|Edit tools
# Purpose: Check if the file being written is within the current wave's ownership.
#          If outside ownership → exit 2 (BLOCK) and freeze.
#
# Unlike SunForge (warn only), Riptide FREEZES on boundary violations.
# Exit 0 = allow, Exit 2 = block

# Read JSON from stdin
INPUT=$(cat)

# Graceful fallback if jq is not available
if ! command -v jq &>/dev/null; then
  exit 0
fi

# Extract the file path from tool_input
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null)

# If we couldn't parse the file path, allow (graceful fallback)
if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# Project directory
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
MODULE_MAP="$PROJECT_DIR/docs/MODULE_MAP.md"

# If MODULE_MAP.md doesn't exist, allow (not yet configured)
if [ ! -f "$MODULE_MAP" ]; then
  exit 0
fi

# Determine current wave from the git branch name
# Expected format: feature/wave-{N}-{name}
CURRENT_BRANCH=$(git -C "$PROJECT_DIR" branch --show-current 2>/dev/null || echo "")
CURRENT_WAVE=""

if [ -n "$CURRENT_BRANCH" ]; then
  # Extract wave identifier from branch name (e.g., "wave-a" from "feature/wave-a-platform-core")
  CURRENT_WAVE=$(echo "$CURRENT_BRANCH" | grep -oE 'wave-[a-zA-Z0-9]+' | head -1)
fi

# If we can't determine the current wave, allow (graceful fallback)
if [ -z "$CURRENT_WAVE" ]; then
  exit 0
fi

# Parse MODULE_MAP.md to find the current wave's owned globs
# Format expected:
#   ### Wave A: name
#   **Owns**:
#   - `glob/pattern/**`
IN_CURRENT_WAVE=false
OWNED_GLOBS=()

while IFS= read -r line; do
  # Detect wave headers (### Wave X: name)
  if echo "$line" | grep -qiE '^###\s+wave'; then
    WAVE_ID=$(echo "$line" | grep -oiE 'wave[- ][a-zA-Z0-9]+' | head -1 | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
    if [ "$WAVE_ID" = "$CURRENT_WAVE" ]; then
      IN_CURRENT_WAVE=true
    else
      IN_CURRENT_WAVE=false
    fi
    continue
  fi

  # If we're in the current wave section, collect owned globs
  if [ "$IN_CURRENT_WAVE" = true ]; then
    # Match lines like: - `path/pattern/**`
    GLOB=$(echo "$line" | grep -oE '`[^`]+`' | tr -d '`')
    if [ -n "$GLOB" ]; then
      OWNED_GLOBS+=("$GLOB")
    fi
  fi
done < "$MODULE_MAP"

# If no globs found for this wave, allow (might be misconfigured)
if [ ${#OWNED_GLOBS[@]} -eq 0 ]; then
  exit 0
fi

# Check if the file path matches any owned glob
for GLOB in "${OWNED_GLOBS[@]}"; do
  # Convert glob to a regex-friendly pattern for matching
  # Replace ** with a match-all pattern, * with single-level match
  PATTERN=$(echo "$GLOB" | sed 's/\*\*/DOUBLESTAR/g' | sed 's/\*/[^\/]*/g' | sed 's/DOUBLESTAR/.*/g')

  if echo "$FILE_PATH" | grep -qE "^$PATTERN"; then
    # File is within ownership — allow
    exit 0
  fi
done

# File is OUTSIDE the wave's ownership — FREEZE
STATUS_FILE="$PROJECT_DIR/.riptide/status.json"
if [ -f "$STATUS_FILE" ] && command -v jq &>/dev/null; then
  TMP=$(jq --arg reason "Module boundary violation: $FILE_PATH is outside $CURRENT_WAVE ownership" \
    '.frozen += [{"reason": $reason, "timestamp": now | tostring}]' "$STATUS_FILE" 2>/dev/null)
  if [ -n "$TMP" ]; then
    echo "$TMP" > "$STATUS_FILE"
  fi
fi

echo "BLOCKED: File '$FILE_PATH' is outside wave '$CURRENT_WAVE' ownership boundary." >&2
echo "Owned globs: ${OWNED_GLOBS[*]}" >&2
echo "FROZEN: Module boundary violation. Reassign file ownership or restructure tides." >&2
exit 2
