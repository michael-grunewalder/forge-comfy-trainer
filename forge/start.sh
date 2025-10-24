#!/bin/bash
set -euo pipefail

log() { printf "\033[1;33m[INFO]\033[0m %s\n" "$*"; }
ok()  { printf "\033[1;32m[SUCCESS]\033[0m %s\n" "$*"; }
err() { printf "\033[1;31m[ERROR]\033[0m %s\n" "$*"; }

APP_NAME="${APP_NAME:-Forge}"
APP_PATH="${APP_PATH:-/workspace/Apps/Forge}"
PY_PATH="${PY_PATH:-/workspace/Python/Forge}"
TOOLS_PATH="${TOOLS_PATH:-/workspace/tools}"
JUPYTER_PORT="${JUPYTER_PORT:-8889}"
START_JUPYTER="${START_JUPYTER:-true}"
FORGE_ARGS="${FORGE_ARGS:-}" # SDXL-Optimizations from Dockerfile
# NEW: Force install control variable (default to 0/false)
FORCE_INSTALL="${FORCE_INSTALL:-0}" 
DATA_ROOT="/workspace/Shared" # Basisordner für Modelle

# Ordnerstruktur sicherstellen
mkdir -p "$TOOLS_PATH" "$APP_PATH" "$PY_PATH" "$DATA_ROOT/models/Stable-diffusion" "$DATA_ROOT/models/VAE" "$DATA_ROOT/models/Lora"

# 1) Python venv
if [[ ! -x "$PY_PATH/bin/python3" ]]; then
  log "Creating Python venv at $PY_PATH…"
  python3 -m venv "$PY_PATH"
  source "$PY_PATH/bin/activate"
  pip install --upgrade pip wheel jupyterlab
  ok "Venv ready."
else
  source "$PY_PATH/bin/activate"
  ok "Using existing venv."
fi

# 2) App code (Handling Force Install)
if [[ "$FORCE_INSTALL" == "1" ]]; then
  log "FORCE_INSTALL is set to 1. Deleting and cloning Forge…"
  rm -rf "$APP_PATH"
  git clone https://github.com/lllyasviel/stable-diffusion-webui-forge.git "$APP_PATH"
  ok "Forge repo ready (Forced clone)."
elif [[ ! -d "$APP_PATH/.git" ]]; then
  log "Cloning Forge into $APP_PATH (First time install)…"
  rm -rf "$APP_PATH"
  git clone https://github.com/lllyasviel/stable-diffusion-webui-forge.git "$APP_PATH"
  ok "Forge repo ready (Initial clone)."
else
  log "Reusing and updating Forge repo…"
  cd "$APP_PATH"
  git pull
  ok "Forge repo updated."
fi

# 3) Install requirements (Crucial: cd BEFORE pip install!)
log "Installing/Updating Forge requirements…"
cd "$APP_PATH" # <--- Ensures we are in the Forge directory
pip install -r requirements.txt
ok "Requirements ready."

# 4) Optional Jupyter
if [[ "$START_JUPYTER" == "true" ]]; then
  log "Starting JupyterLab on ${JUPYTER_PORT}…"
  nohup jupyter lab --ip=0.0.0.0 --port="${JUPYTER_PORT}" \
        --NotebookApp.token='' --NotebookApp.password='' --no-browser \
        > "$TOOLS_PATH/jupyter.log" 2>&1 &
  ok "JupyterLab running."
fi

# 5) Launch (using SDXL optimizations)
log "Launching Forge on 7860…"
exec python launch.py --listen --port 7860 \
     --data-dir "$DATA_ROOT" \
     $FORGE_ARGS \
     --skip-version-check