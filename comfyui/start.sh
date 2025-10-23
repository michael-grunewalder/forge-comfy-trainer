#!/usr/bin/env bash
set -e

# ========== Bearny's AI Lab ==========
BUILD_DATE="$(date -u +'%Y-%m-%d %H:%M:%S UTC')"
VERSION="${APP_VERSION:-v1.0.0}"
echo "=============================================================="
echo " 🧠  Bearny's AI Lab - ComfyUI Node"
echo "     Version: $VERSION"
echo "     Build:   $BUILD_DATE"
echo "=============================================================="

# ---------- Directories ----------
COMFY_DIR="/workspace/comfyui"
SHARED_MODELS="/workspace/shared/models"
LOGDIR="/workspace/shared/logs"
mkdir -p "$COMFY_DIR" "$SHARED_MODELS" "$LOGDIR"

# ---------- Clone ComfyUI if missing ----------
if [ ! -d "$COMFY_DIR/.git" ]; then
  echo "[Setup] Cloning ComfyUI..."
  git clone https://github.com/comfyanonymous/ComfyUI.git "$COMFY_DIR"
else
  echo "[Setup] ComfyUI already present, skipping clone."
fi

# ---------- Install or update ComfyUI-Manager ----------
cd "$COMFY_DIR/custom_nodes"
if [ ! -d "ComfyUI-Manager" ]; then
  echo "[Setup] Installing ComfyUI-Manager..."
  git clone https://github.com/ltdrdata/ComfyUI-Manager.git
else
  echo "[Setup] Updating ComfyUI-Manager..."
  cd ComfyUI-Manager && git pull && cd ..
fi

# ---------- Symlink models ----------
ln -sf "$SHARED_MODELS" "$COMFY_DIR/models"

# ---------- Launch background services ----------
echo "[Start] Launching JupyterLab..."
nohup jupyter-lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root \
  > "$LOGDIR/jupyter.log" 2>&1 &

echo "[Start] Launching ComfyUI..."
cd "$COMFY_DIR"
nohup python main.py --listen 0.0.0.0 --port 8188 > "$LOGDIR/comfyui.log" 2>&1 &

# ---------- Final message ----------
sleep 5
echo "✅ ComfyUI + Manager + Jupyter are running."
echo "   → ComfyUI:   http://<pod-address>:8188"
echo "   → Jupyter:   http://<pod-address>:8888/lab"
echo "Logs in: $LOGDIR"
echo "=============================================================="

# Keep container alive
tail -f /dev/null
