#!/bin/bash
# dashboard.sh — Start localhost server for the Riptide status dashboard
# Usage: dashboard.sh {target-project-path} [port]
# Serves dashboard/index.html and opens browser to localhost.

set -euo pipefail

# --- Validate arguments ---
if [ -z "${1:-}" ]; then
  echo "Usage: dashboard.sh <target-project-path> [port]"
  echo "Error: target project path is required."
  exit 1
fi

TARGET="$(cd "$1" 2>/dev/null && pwd)" || {
  echo "Error: target path '$1' does not exist or is not a directory."
  exit 1
}

PORT="${2:-3000}"

# --- Validate dashboard exists ---
DASHBOARD_DIR="$TARGET/dashboard"
if [ ! -f "$DASHBOARD_DIR/index.html" ]; then
  echo "Error: dashboard/index.html not found in $TARGET"
  echo "Run bootstrap.sh first to deploy the dashboard."
  exit 1
fi

echo "Starting Riptide dashboard..."
echo "  Serving: $DASHBOARD_DIR"
echo "  URL:     http://localhost:$PORT"
echo ""
echo "Press Ctrl+C to stop."
echo ""

# --- Open browser (background, non-blocking) ---
if command -v open &>/dev/null; then
  # macOS
  open "http://localhost:$PORT" &
elif command -v xdg-open &>/dev/null; then
  # Linux
  xdg-open "http://localhost:$PORT" &
fi

# --- Start HTTP server ---
# Use Python's built-in http.server (available on macOS and most Linux)
if command -v python3 &>/dev/null; then
  cd "$DASHBOARD_DIR"
  python3 -m http.server "$PORT"
elif command -v python &>/dev/null; then
  cd "$DASHBOARD_DIR"
  python -m http.server "$PORT"
else
  echo "Error: Python not found. Install Python 3 to run the dashboard server."
  exit 1
fi
