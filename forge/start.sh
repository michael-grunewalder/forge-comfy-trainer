#!/bin/bash
set -euo pipefail

log() { printf "\033[1;33m[INFO]\033[0m %s\n" "$*"; }
ok()  { printf "\033[1;32m[SUCCESS]\033[0m %s\n" "$*"; }
err() { printf "\033[1;31m[ERROR]\033[0m %s\n" "$*"; }

APP_NAME="${APP_NAME:-Forge}"
APP_PATH="${APP_PATH:-/workspace/Apps/Forge}"
PY_PATH="${PY_PATH:-/workspace/Python/Forge}"
SHARED_MODELS="${SHARED_MODELS:-/workspace/Shared}"
TOOLS_PATH="${TOOLS_PATH:-/workspace/tools}"
JUPYTER_PORT="${JUPYTER_PORT:-8889}"
START_JUPYTER="${START_JUPYTER:-true}"

mkdir -p "$TOOLS_PATH" "$APP_PATH" "$PY_PATH" "$SHARED_MODELS"

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

# 2) App code
if [[ ! -d "$APP_PATH/.git" ]]; then
  log "Cloning Forge into $APP_PATH…"
  rm -rf "$APP_PATH"
  git clone https://github.com/lllyasviel/stable-diffusion-webui-forge.git "$APP_PATH"
  ok "Forge repo ready."
else
  ok "Reusing Forge repo."
fi

# 3) Optional Jupyter
if [[ "$START_JUPYTER" == "true" ]]; then
  log "Starting JupyterLab on ${JUPYTER_PORT}…"
  nohup jupyter lab --ip=0.0.0.0 --port="${JUPYTER_PORT}" \
        --NotebookApp.token='' --NotebookApp.password='' --no-browser \
        > /workspace/jupyter.log 2>&1 &
else
  log "Jupyter disabled (START_JUPYTER=false)."
fi

# 4) Launch (Forge expects boolean --listen; do NOT pass 0.0.0.0)
# export MODEL_PATH="$SHARED_MODELS"
cd "$APP_PATH"

#log "Launching Forge on 7860… (first run may pip-install inside venv)"
#exec python launch.py --listen --port 7860 \
#     --data-dir "$SHARED_MODELS" --no-half-vae
# Setze DATA_ROOT auf den übergeordneten Ordner /workspace/Shared
export DATA_ROOT="/workspace/Shared"

log "Launching Forge on 7860… (first run may pip-install inside venv)"
exec python launch.py --listen --port 7860 \
     --data-dir "$DATA_ROOT" \
     --no-half-vae \
     --opt-sdp-attention \
     --upcast-sampling \
     --disable-nan-check \
     --skip-version-check
