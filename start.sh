#!/bin/bash
set -e

APP_VERSION="${APP_VERSION:-v1.0.0s}"
echo "=============================================================="
echo " 🧠  Bearny's AI Lab] Booting..."
echo "     Version: ${APP_VERSION}"
echo "     Boot:    $(date -u)"
echo "=============================================================="

echo "===== Bearny's AI Lab startup ====="
echo "[Info] Version 1.0 (2025-10-22)"

# --- Paths ---
APPS_DIR="/workspace/apps"
SHARED="/workspace/shared"
LOGS_DIR="$SHARED/logs"
VENV="/opt/venv"

mkdir -p "$APPS_DIR" "$LOGS_DIR/forge" "$LOGS_DIR/comfyui" "$LOGS_DIR/jupyter" "$LOGS_DIR/kohya"

# --- Check virtualenv ---
if [ ! -d "$VENV" ]; then
  echo "[Setup] Creating Python virtualenv..."
  python3 -m venv $VENV
  $VENV/pip install --upgrade pip setuptools wheel
fi

# --- Core dependencies ---
echo "[Setup] Ensuring base Python packages..."
$VENV/pip install --no-cache-dir -U torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
$VENV/pip install --no-cache-dir -U xformers==0.0.27.post2 \
  fastapi uvicorn gradio==4.36.1 einops safetensors opencv-python pillow tqdm jupyterlab==4.2.5 tensorboard==2.17.1 bitsandbytes==0.43.3 accelerate==0.33.0

# --- Update or skip ---
UPDATE_ON_START=${UPDATE_ON_START:-false}
if [ "$UPDATE_ON_START" = "true" ]; then
  echo "[Update] Pulling latest versions of all apps..."
  for repo in forge ComfyUI kohya_ss ComfyUI-Manager; do
    if [ -d "$APPS_DIR/$repo/.git" ]; then
      (cd "$APPS_DIR/$repo" && git pull --rebase || true)
    fi
  done
else
  echo "[Info] Skipping updates (UPDATE_ON_START=$UPDATE_ON_START)"
fi

# --- Forge install ---
if [ ! -d "$APPS_DIR/forge" ]; then
  echo "[Setup] Installing Forge..."
  git clone --depth=1 https://github.com/lllyasviel/stable-diffusion-webui-forge.git "$APPS_DIR/forge"
fi

echo "[Forge] Launching on port 7860..."
cd "$APPS_DIR/forge"
nohup $VENV/python launch.py \
  --listen \
  --server-name 0.0.0.0 \
  --port 7860 \
  --xformers \
  --api \
  --skip-version-check \
  --disable-nan-check \
  --no-half \
  --no-half-vae \
  --enable-insecure-extension-access \
  --ckpt-dir /workspace/shared/models/checkpoints \
  --lora-dir /workspace/shared/models/loras \
  --vae-dir /workspace/shared/models/vae \
  --controlnet-dir /workspace/shared/models/controlnet \
  --embeddings-dir /workspace/shared/models/embeddings \
  --data-dir /workspace/shared/configs \
  > "$LOGS_DIR/forge/forge.log" 2>&1 &

# --- ComfyUI + Manager ---
if [ ! -d "$APPS_DIR/ComfyUI" ]; then
  echo "[Setup] Installing ComfyUI..."
  git clone --depth=1 https://github.com/comfyanonymous/ComfyUI.git "$APPS_DIR/ComfyUI"
  cd "$APPS_DIR/ComfyUI"
  $VENV/pip install --no-cache-dir -r requirements.txt || true
fi

COMFY_EXT_DIR="$APPS_DIR/ComfyUI/custom_nodes/ComfyUI-Manager"
if [ ! -d "$COMFY_EXT_DIR" ]; then
  echo "[Setup] Installing ComfyUI Manager..."
  git clone --depth=1 https://github.com/ltdrdata/ComfyUI-Manager.git "$COMFY_EXT_DIR"
else
  echo "[Setup] Updating ComfyUI Manager..."
  (cd "$COMFY_EXT_DIR" && git pull --rebase || true)
fi

echo "[ComfyUI] Launching on port 8188..."
cd "$APPS_DIR/ComfyUI"
nohup $VENV/python main.py --listen 0.0.0.0 --port 8188 \
  > "$LOGS_DIR/comfyui/comfyui.log" 2>&1 &

# --- kohya_ss (optional LoRA GUI) ---
if [ ! -d "$APPS_DIR/kohya_ss" ]; then
  echo "[Setup] Installing kohya_ss..."
  git clone --depth=1 https://github.com/bmaltais/kohya_ss.git "$APPS_DIR/kohya_ss"
fi

echo "[kohya_ss] Launching on port 7861..."
cd "$APPS_DIR/kohya_ss"
nohup $VENV/python kohya_gui.py --listen 0.0.0.0 --server_port 7861 \
  > "$LOGS_DIR/kohya/kohya.log" 2>&1 &

# --- JupyterLab ---
echo "[Jupyter] Launching on port 8888..."
nohup $VENV/python -m jupyterlab \
  --ip=0.0.0.0 --port=8888 --no-browser --NotebookApp.token='' \
  --NotebookApp.password='' --NotebookApp.allow_origin='*' \
  --NotebookApp.notebook_dir=/workspace \
  > "$LOGS_DIR/jupyter/jupyter.log" 2>&1 &

echo "===== All services started ====="
echo " Forge:      http://<pod-url>:7860"
echo " ComfyUI:    http://<pod-url>:8188"
echo " kohya_ss:   http://<pod-url>:7861"
echo " JupyterLab: http://<pod-url>:8888/lab"

# Keep container alive
tail -f /dev/null