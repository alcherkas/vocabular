#!/bin/bash
#
# run-team.sh — Auto-restart orchestrator loop
#
# Starts a Copilot CLI session as the team lead.
# When the session ends (context exhausted), automatically restarts.
# The new session reads repo state and continues where the last left off.
#
# Usage:
#   ./scripts/run-team.sh              # default: use ghcs/copilot
#   ./scripts/run-team.sh claude       # use claude code
#   AGENT_CMD="my-cli" ./scripts/run-team.sh  # custom CLI
#
# To stop: create a STOP file in the repo root
#   touch STOP
#

set -e

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_DIR"

# Determine which CLI to use
if [ -n "$AGENT_CMD" ]; then
    CLI="$AGENT_CMD"
elif [ -n "$1" ]; then
    CLI="$1"
elif command -v ghcs &>/dev/null; then
    CLI="ghcs"
elif command -v copilot &>/dev/null; then
    CLI="copilot"
else
    echo "Error: No CLI found. Set AGENT_CMD or pass as argument."
    echo "Usage: ./scripts/run-team.sh <cli-command>"
    exit 1
fi

PROMPT='You are the team lead for an autonomous agent team.

1. Read docs/ORCHESTRATOR.md — it is your full protocol.
2. Run in TERSE MODE (minimize output to conserve context).
3. Start the infinite main loop immediately. Do NOT ask questions.
4. Scan for work, spawn agents, monitor, merge, reflect, repeat.
5. Do NOT pause between cycles. Keep going until context runs out.

The repo state (GOALS.md, TASKS.md, audit-log.md) tells you exactly where things stand. Pick up from wherever the last session left off.'

SESSION=0

echo "╔══════════════════════════════════════════╗"
echo "║  Agent Team Runner                       ║"
echo "║  CLI: $CLI                               ║"
echo "║  Repo: $REPO_DIR                         ║"
echo "║  Stop: touch STOP in repo root           ║"
echo "╚══════════════════════════════════════════╝"

while true; do
    # Check for stop signal
    if [ -f "$REPO_DIR/STOP" ]; then
        echo ""
        echo "STOP file detected. Shutting down."
        rm -f "$REPO_DIR/STOP"
        break
    fi

    SESSION=$((SESSION + 1))
    echo ""
    echo "═══ Session $SESSION starting at $(date '+%H:%M:%S') ═══"
    echo ""

    # Run the CLI session
    # Adapt this line to your CLI's invocation pattern
    $CLI "$PROMPT" || true

    echo ""
    echo "═══ Session $SESSION ended at $(date '+%H:%M:%S') ═══"

    # Check for stop signal again
    if [ -f "$REPO_DIR/STOP" ]; then
        echo "STOP file detected. Shutting down."
        rm -f "$REPO_DIR/STOP"
        break
    fi

    # Brief pause before restart
    echo "Restarting in 5 seconds... (touch STOP to cancel)"
    sleep 5
done

echo ""
echo "Agent team runner stopped."
echo "Sessions completed: $SESSION"
echo "Check docs/audit-log.md for full history."
