#!/bin/bash
set -Eeuo pipefail

WORK=/workspace
COMFY_DIR="$WORK/comfyui"
PORT="${PORT:-8188}"
JUPYTER_PORT="${JUPYTER_PORT:-8888}"
COMFY_REPO="https://github.com/comfyanonymous/ComfyUI"
COMFY_MANAGER_REPO="https://github.com/ltdrdata/ComfyUI-Manager"

mkdir -p "$WORK"
cd "$WORK"

# --- 1) Install ComfyUI persistently ---
if [ ! -d "$COMFY_DIR" ]; then
  echo "=== First run: cloning ComfyUI ==="
  git clone "$COMFY_REPO" comfyui
  cd comfyui
  python -m venv venv
  source venv/bin/activate
  pip install --upgrade pip
  pip install -r requirements.txt
else
  echo "=== ComfyUI already present ==="
  cd comfyui
fi

# --- 2) Ensure venv is usable ---
if [ ! -f "venv/bin/activate" ]; then
  echo "=== Recreating venv ==="
  python -m venv venv
  source venv/bin/activate
  pip install --upgrade pip
  pip install -r requirements.txt
else
  source venv/bin/activate
fi

# --- 3) Install Comfy Manager (persistent) ---
if [ ! -d "$COMFY_DIR/custom_nodes/ComfyUI-Manager" ]; then
  echo "=== Installing ComfyUI Manager ==="
  mkdir -p "$COMFY_DIR/custom_nodes"
  git clone "$COMFY_MANAGER_REPO" "$COMFY_DIR/custom_nodes/ComfyUI-Manager"
fi

# --- 4) Link shared models directory ---
mkdir -p "$WORK/models"
if [ ! -L "$COMFY_DIR/models" ]; then
  rm -rf "$COMFY_DIR/models" || true
  ln -s "$WORK/models" "$COMFY_DIR/models"
fi

# --- 5) Optional: Start Jupyter ---
if [ "${START_JUPYTER:-false}" = "true" ]; then
  echo "=== Starting JupyterLab on ${JUPYTER_PORT} ==="
  nohup jupyter lab --ip=0.0.0.0 --port="${JUPYTER_PORT}" --no-browser --NotebookApp.token='' --NotebookApp.password='' >/workspace/jupyter.log 2>&1 &
fi

# --- 6) Launch ComfyUI ---
echo "=== Starting ComfyUI on port ${PORT} ==="
exec python main.py --listen 0.0.0.0 --port "${PORT}"
