#!/bin/bash
set -e

log_info()    { echo -e "\033[1;33m[INFO]\033[0m $1"; }
log_success() { echo -e "\033[1;32m[SUCCESS]\033[0m $1"; }
log_error()   { echo -e "\033[1;31m[ERROR]\033[0m $1"; }

APP_NAME="Trainer"
APP_PATH="/workspace/Apps/${APP_NAME}"
PYTHON_PATH="/workspace/Python/${APP_NAME}"
SHARED_MODELS="/workspace/Shared/models"
TOOLS_PATH="/workspace/tools"
JUPYTER_PORT=8890
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
  log_info "App source not found in $APP_PATH. Cloning KohyaSS..."
  rm -rf "$APP_PATH"
  git clone https://github.com/bmaltais/kohya_ss.git "$APP_PATH"
  cd "$APP_PATH"
  pip install -r requirements.txt
  log_success "KohyaSS repository cloned and dependencies installed."
else
  log_success "Reusing existing KohyaSS repository."
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
cd "$APP_PATH"

log_info "Launching KohyaSS GUI on port 7861..."
python kohya_gui.py --listen 0.0.0.0 --port 7861