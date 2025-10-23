#!/bin/bash
set -e

log_info()    { echo -e "\033[1;33m[INFO]\033[0m $1"; }
log_success() { echo -e "\033[1;32m[SUCCESS]\033[0m $1"; }
log_error()   { echo -e "\033[1;31m[ERROR]\033[0m $1"; }

APP_PATH="/workspace/Apps/Forge"
PYTHON_PATH="/workspace/Python/Forge"
SHARED_MODELS="/workspace/Shared/models"
TOOLS_PATH="/workspace/tools"
JUPYTER_PORT=8889
START_JUPYTER=${START_JUPYTER:-true}

mkdir -p "$TOOLS_PATH" "$APP_PATH" "$PYTHON_PATH" "$SHARED_MODELS"

log_info "Starting Forge…"

# Python env
if [ ! -d "$PYTHON_PATH/bin" ]; then
  log_info "Creating Python venv…"
  python3 -m venv "$PYTHON_PATH"
  source "$PYTHON_PATH/bin/activate"
  pip install --upgrade pip jupyterlab
  log_success "Venv ready."
else
  source "$PYTHON_PATH/bin/activate"
  pip install -q jupyterlab
  log_success "Reusing venv."
fi

# App install
if [ ! -d "$APP_PATH/.git" ]; then
  log_info "Cloning Forge…"
  git clone https://github.com/lllyasviel/stable-diffusion-webui-forge.git "$APP_PATH"
  log_success "Forge installed."
else
  log_success "Reusing Forge."
fi

# Jupyter (optional)
if [ "$START_JUPYTER" = true ]; then
  log_info "Starting JupyterLab on ${JUPYTER_PORT}…"
  nohup jupyter lab --ip=0.0.0.0 --port=${JUPYTER_PORT} --NotebookApp.token='' --NotebookApp.password='' --no-browser > /workspace/jupyter.log 2>&1 &
else
  log_info "Jupyter disabled (START_JUPYTER=false)."
fi

# Launch Forge
cd "$APP_PATH"
export MODEL_PATH="$SHARED_MODELS"
log_info "Launching Forge on 7860…"
python launch.py --listen 0.0.0.0 --port 7860 --data-dir "$SHARED_MODELS" --no-half-vae
