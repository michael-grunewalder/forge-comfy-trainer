#!/bin/bash
set -e
llog_info()    { echo -e "\033[1;33m[INFO]\033[0m $1"; }
log_success() { echo -e "\033[1;32m[SUCCESS]\033[0m $1"; }
log_error()   { echo -e "\033[1;31m[ERROR]\033[0m $1"; }

mkdir -p /workspace/tools

APP_PATH="/workspace/Apps/Trainer"
PYTHON_PATH="/workspace/Python/Trainer"
SHARED_MODELS="/workspace/Shared/models"
JUPYTER_PORT=8890
START_JUPYTER=${START_JUPYTER:-true}

log_info "Starting KohyaSS Trainer container..."
mkdir -p "$APP_PATH" "$PYTHON_PATH" "$SHARED_MODELS"

if [ ! -d "$PYTHON_PATH/bin" ]; then
  log_info "Setting up Python environment..."
  python3 -m venv "$PYTHON_PATH"
  source "$PYTHON_PATH/bin/activate"
  pip install --upgrade pip jupyterlab
  log_success "Python environment ready."
else
  source "$PYTHON_PATH/bin/activate"
  pip install -q jupyterlab
  log_success "Reusing cached Python environment."
fi

if [ ! -d "$APP_PATH/.git" ]; then
  log_info "Installing KohyaSS..."
  git clone https://github.com/bmaltais/kohya_ss.git "$APP_PATH"
  cd "$APP_PATH"
  pip install -r requirements.txt
  log_success "KohyaSS installed."
else
  log_success "Reusing cached KohyaSS installation."
fi

if [ "$START_JUPYTER" = true ]; then
  log_info "Launching JupyterLab on port ${JUPYTER_PORT}..."
  nohup jupyter lab --ip=0.0.0.0 --port=${JUPYTER_PORT} --NotebookApp.token='' --NotebookApp.password='' --no-browser > /workspace/jupyter.log 2>&1 &
else
  log_info "Skipping JupyterLab startup (START_JUPYTER=false)."
fi

cd "$APP_PATH"
log_info "Launching KohyaSS GUI on port 7861..."
python kohya_gui.py --listen 0.0.0.0 --port 7861