#!/bin/bash
set -e

log_info()    { echo -e "\033[1;33m[INFO]\033[0m $1"; }
log_success() { echo -e "\033[1;32m[SUCCESS]\033[0m $1"; }
log_error()   { echo -e "\033[1;31m[ERROR]\033[0m $1"; }

APP_NAME="Forge"
APP_PATH="/workspace/Apps/${APP_NAME}"
PYTHON_PATH="/workspace/Python/${APP_NAME}"
SHARED_MODELS="/workspace/Shared/models"
TOOLS_PATH="/workspace/tools"
JUPYTER_PORT=8889
START_JUPYTER=${START_JUPYTER:-true}

mkdir -p "$TOOLS_PATH" "$APP_PATH" "$PYTHON_PATH" "$SHARED_MODELS"

# ---------- 1. Python Environment Check ----------
if [ ! -x "$PYTHON_PATH/bin/python3" ]; then
  log_info "Python environment missing. Creating fresh venv..."
  python3 -m venv "$PYTHON_PATH"
  source "$PYTHON_PATH/bin/activate"
  pip install --upgrade pip jupyterlab
  log_success "Python environment created."
else
  source "$PYTHON_PATH/bin/activate"
  log_success "Using existing Python environment."
fi

# ---------- 2. Application Code Check ----------
if [ ! -d "$APP_PATH/.git" ]; then
  log_info "App source not found in $APP_PATH. Cloning Forge..."
  rm -rf "$APP_PATH"
  git clone https://github.com/lllyasviel/stable-diffusion-webui-forge.git "$APP_PATH"
  log_success "Forge repository cloned."
else
  log_success "Reusing existing Forge repository."
fi

# ---------- 3. Optional Jupyter ----------
if [ "$START_JUPYTER" = true ]; then
  log_info "Starting JupyterLab on ${JUPYTER_PORT}..."
  nohup jupyter lab --ip=0.0.0.0 --port=${JUPYTER_PORT} \
        --NotebookApp.token='' --NotebookApp.password='' --no-browser \
        > /workspace/jupyter.log 2>&1 &
else
  log_info "Jupyter disabled (START_JUPYTER=false)."
fi

# ---------- 4. Launch Application ----------
export MODEL_PATH="$SHARED_MODELS"
cd "$APP_PATH"

log_info "Launching Forge on port 7860..."
python launch.py --listen 0.0.0.0 --port 7860 \
                 --data-dir "$SHARED_MODELS" --no-half-vae