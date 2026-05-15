#!/bin/bash
# block-dangerous-git.sh
# Trigger: PreToolUse on Bash tool
# Purpose: Block dangerous git operations that could cause data loss.
#
# Exit 0 = allow, Exit 2 = block

# Read JSON from stdin
INPUT=$(cat)

# Graceful fallback if jq is not available
if ! command -v jq &>/dev/null; then
  exit 0
fi

# Extract the command from tool_input
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

# If we couldn't parse the command or it's empty, allow
if [ -z "$COMMAND" ]; then
  exit 0
fi

# Only check git commands
if ! echo "$COMMAND" | grep -q "git "; then
  exit 0
fi

# Block dangerous patterns

# 1. git push --force / git push -f
if echo "$COMMAND" | grep -qE 'git\s+push\s+.*(-f|--force)\b'; then
  echo "BLOCKED: git push --force is not allowed. Use --force-with-lease if absolutely necessary." >&2
  exit 2
fi

# 2. git reset --hard
if echo "$COMMAND" | grep -qE 'git\s+reset\s+--hard'; then
  echo "BLOCKED: git reset --hard can cause data loss. Use git stash or git reset --soft instead." >&2
  exit 2
fi

# 3. git clean -f / git clean -fd
if echo "$COMMAND" | grep -qE 'git\s+clean\s+-[a-zA-Z]*f'; then
  echo "BLOCKED: git clean -f can permanently delete untracked files. Review files manually first." >&2
  exit 2
fi

# 4. git checkout . (discard all changes)
if echo "$COMMAND" | grep -qE 'git\s+checkout\s+\.$'; then
  echo "BLOCKED: git checkout . discards all uncommitted changes. Use git stash to save changes first." >&2
  exit 2
fi

# 5. git branch -D (force delete)
if echo "$COMMAND" | grep -qE 'git\s+branch\s+-D\b'; then
  echo "BLOCKED: git branch -D force-deletes a branch. Use git branch -d (lowercase) for safe delete." >&2
  exit 2
fi

# All checks passed — allow
exit 0
