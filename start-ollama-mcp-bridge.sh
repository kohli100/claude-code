#!/usr/bin/env bash
# Ollama MCP Bridge — starts a local proxy at localhost:8000
# that adds MCP tool support to every /api/chat request sent to Ollama.
#
# Usage:
#   ./start-ollama-mcp-bridge.sh           # foreground (logs visible)
#   ./start-ollama-mcp-bridge.sh --bg      # background (logs go to bridge.log)
#
# Clients: point any Ollama-compatible client to http://localhost:8000
# instead of http://localhost:11434

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BRIDGE="/Users/sukeshkohli/miniforge3/bin/ollama-mcp-bridge"
CONFIG="$SCRIPT_DIR/mcp-config.json"
LOG="$SCRIPT_DIR/bridge.log"

# Verify Ollama is running before starting
if ! curl -sf http://localhost:11434/api/tags > /dev/null 2>&1; then
  echo "ERROR: Ollama is not running at localhost:11434"
  echo "Start Ollama first: open the Ollama app or run 'ollama serve'"
  exit 1
fi

echo "Ollama detected at localhost:11434 ✓"
echo "Starting Ollama MCP Bridge on http://localhost:8000"
echo "  Config:   $CONFIG"
echo "  Ollama:   http://localhost:11434"
echo "  Max tool rounds: 10"
echo ""

if [[ "$1" == "--bg" ]]; then
  echo "Running in background — logs: $LOG"
  nohup "$BRIDGE" \
    --config "$CONFIG" \
    --ollama-url http://localhost:11434 \
    --max-tool-rounds 10 \
    --system-prompt "You are a helpful AI assistant with access to local tools. Use them when relevant." \
    > "$LOG" 2>&1 &
  echo "Bridge PID: $!"
  echo "Stop with: kill \$(lsof -ti:8000)"
else
  "$BRIDGE" \
    --config "$CONFIG" \
    --ollama-url http://localhost:11434 \
    --max-tool-rounds 10 \
    --system-prompt "You are a helpful AI assistant with access to local tools. Use them when relevant."
fi
