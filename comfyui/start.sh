#!/bin/bash
set -euo pipefail

log() { printf "\033[1;33m[INFO]\033[0m %s\n" "$*"; }
ok()  { printf "\033[1;32m[SUCCESS]\033[0m %s\n" "$*"; }
err() { printf "\033[1;31m[ERROR]\033[0m %s\n" "$*"; }

APP_NAME="${APP_NAME:-ComfyUI}"
APP_PATH="${APP_PATH:-/workspace/Apps/ComfyUI}"
PY_PATH="${PY_PATH:-/workspace/Python/ComfyUI}"
SHARED_MODELS="${SHARED_MODELS:-/workspace/Shared/models}"
TOOLS_PATH="${TOOLS_PATH:-/workspace/tools}"
JUPYTER_PORT="${JUPYTER_PORT:-8888}"
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
  log "Cloning ComfyUI into $APP_PATH…"
  rm -rf "$APP_PATH"
  git clone https://github.com/comfyanonymous/ComfyUI.git "$APP_PATH"
  git clone https://github.com/ltdrdata/ComfyUI-Manager.git "$APP_PATH/custom_nodes/ComfyUI-Manager"
  ok "ComfyUI installed."
else
  ok "Reusing ComfyUI repo."
fi

# 3) Jupyter (optional)
if [[ "$START_JUPYTER" == "true" ]]; then
  log "Starting JupyterLab on ${JUPYTER_PORT}…"
  nohup jupyter lab --ip=0.0.0.0 --port="${JUPYTER_PORT}" \
        --NotebookApp.token='' --NotebookApp.password='' --no-browser \
        > /workspace/jupyter.log 2>&1 &
else
  log "Jupyter disabled (START_JUPYTER=false)."
fi

# 4) Launch
export COMFYUI_MODELS_PATH="$SHARED_MODELS"
cd "$APP_PATH"
log "Launching ComfyUI on 8188…"
exec python main.py --listen 0.0.0.0 --port 8188