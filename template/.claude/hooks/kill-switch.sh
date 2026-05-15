#!/bin/bash
# kill-switch.sh
# Trigger: PostToolUse on Bash tool
# Purpose: Monitor test output for consecutive failures and time stalls.
#          After 3 consecutive failures on the same test OR 10min stall → FREEZE.
#
# Exit 0 always (informational — agent reads output and decides to stop).
# Writes FROZEN status to .riptide/status.json on trigger.

# Read JSON from stdin (Claude Code hook format)
INPUT=$(cat)

# Graceful fallback if jq is not available
if ! command -v jq &>/dev/null; then
  exit 0
fi

# Extract the tool output from the hook payload
TOOL_OUTPUT=$(echo "$INPUT" | jq -r '.tool_output // empty' 2>/dev/null)

# If no output or not a test-related command, skip
if [ -z "$TOOL_OUTPUT" ]; then
  exit 0
fi

# Project directory
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
STATE_FILE="$PROJECT_DIR/.riptide/.kill-switch-state"
STATUS_FILE="$PROJECT_DIR/.riptide/status.json"

# Thresholds
MAX_CONSECUTIVE_FAILURES=3
MAX_STALL_SECONDS=600  # 10 minutes

# Ensure .riptide directory exists
mkdir -p "$PROJECT_DIR/.riptide"

# Initialize state file if it doesn't exist
if [ ! -f "$STATE_FILE" ]; then
  cat > "$STATE_FILE" << EOF
{
  "consecutive_failures": 0,
  "last_failing_test": "",
  "last_activity": $(date +%s)
}
EOF
fi

# Read current state
FAILURES=$(jq -r '.consecutive_failures // 0' "$STATE_FILE" 2>/dev/null || echo "0")
LAST_TEST=$(jq -r '.last_failing_test // ""' "$STATE_FILE" 2>/dev/null || echo "")
LAST_ACTIVITY=$(jq -r '.last_activity // 0' "$STATE_FILE" 2>/dev/null || echo "0")

# --- Check for stall (10 minutes without progress) ---
NOW=$(date +%s)
if [ "$LAST_ACTIVITY" -gt 0 ]; then
  ELAPSED=$((NOW - LAST_ACTIVITY))
  if [ "$ELAPSED" -ge "$MAX_STALL_SECONDS" ]; then
    # Write FROZEN status
    if [ -f "$STATUS_FILE" ]; then
      TMP=$(jq --arg reason "Stall detected: ${ELAPSED}s without progress (limit: ${MAX_STALL_SECONDS}s)" \
        '.frozen += [{"reason": $reason, "timestamp": now | tostring}]' "$STATUS_FILE" 2>/dev/null)
      if [ -n "$TMP" ]; then
        echo "$TMP" > "$STATUS_FILE"
      fi
    fi
    echo "FROZEN: Agent stalled for $((ELAPSED / 60)) minutes without progress. Human intervention required."
    exit 0
  fi
fi

# --- Detect test failures in output ---
# Look for common test failure patterns
FAILED_TEST=""
if echo "$TOOL_OUTPUT" | grep -qiE '(FAIL|FAILED|ERROR|AssertionError)'; then
  # Try to extract the specific test name
  FAILED_TEST=$(echo "$TOOL_OUTPUT" | grep -oE '(FAIL|FAILED)\s+\S+' | head -1 | sed 's/^[A-Z]*\s*//')
  if [ -z "$FAILED_TEST" ]; then
    FAILED_TEST=$(echo "$TOOL_OUTPUT" | grep -oE 'test_\w+|it\s+"[^"]*"|describe\s+"[^"]*"' | head -1)
  fi
  if [ -z "$FAILED_TEST" ]; then
    FAILED_TEST="unknown_test"
  fi
fi

# --- Update state based on detection ---
if [ -n "$FAILED_TEST" ]; then
  # A test failure was detected
  if [ "$FAILED_TEST" = "$LAST_TEST" ]; then
    # Same test failing again — increment
    FAILURES=$((FAILURES + 1))
  else
    # Different test — reset counter
    FAILURES=1
    LAST_TEST="$FAILED_TEST"
  fi
elif echo "$TOOL_OUTPUT" | grep -qiE '(PASS|passed|✓|✔|OK|success)'; then
  # Tests passed — reset failure counter
  FAILURES=0
  LAST_TEST=""
fi

# Write updated state
cat > "$STATE_FILE" << EOF
{
  "consecutive_failures": $FAILURES,
  "last_failing_test": "$LAST_TEST",
  "last_activity": $NOW
}
EOF

# --- Check failure threshold ---
if [ "$FAILURES" -ge "$MAX_CONSECUTIVE_FAILURES" ]; then
  # Write FROZEN status
  if [ -f "$STATUS_FILE" ]; then
    TMP=$(jq --arg reason "3 consecutive failures on: $LAST_TEST" \
      '.frozen += [{"reason": $reason, "timestamp": now | tostring}]' "$STATUS_FILE" 2>/dev/null)
    if [ -n "$TMP" ]; then
      echo "$TMP" > "$STATUS_FILE"
    fi
  fi
  echo "FROZEN: 3 consecutive test failures on '$LAST_TEST'. Human intervention required."
  exit 0
fi

# All clear
exit 0
