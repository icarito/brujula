#!/usr/bin/env bash
# Wrapper para iniciar Godot MCP con Node, habilitando DEBUG por defecto y autodetectando GODOT_PATH.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NODE_BIN="${NODE_BIN:-node}"

# DEBUG por defecto
export DEBUG="${DEBUG:-true}"

# Autodetectar Godot si no viene definido
if [[ -z "${GODOT_PATH:-}" ]]; then
  if command -v godot-preview >/dev/null 2>&1; then
    export GODOT_PATH="$(command -v godot-preview)"
  elif command -v godot4 >/dev/null 2>&1; then
    export GODOT_PATH="$(command -v godot4)"
  elif command -v godot >/dev/null 2>&1; then
    export GODOT_PATH="$(command -v godot)"
  fi
fi

echo "[godot-mcp] DEBUG=$DEBUG GODOT_PATH=${GODOT_PATH:-unset}"
exec "$NODE_BIN" "$SCRIPT_DIR/build/index.js" "$@"
