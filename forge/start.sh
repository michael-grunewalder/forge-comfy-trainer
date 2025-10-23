#!/usr/bin/env bash
set -e

# ==============================================================
# 🧠  Bearny's AI Lab - Forge Node
# ==============================================================

BUILD_DATE="$(date -u +'%Y-%m-%d %H:%M:%S UTC')"
VERSION="${APP_VERSION:-v1.0.0}"
echo "=============================================================="
echo " 🧠  Bearny's AI Lab - Forge Node"
echo "     Version: $VERSION"
echo "     Build:   $BUILD_DATE"
echo "=============================================================="

# ---------- Directories ----------
FORGE_DIR="/workspace/forge"
SHARED_MODELS="/workspace/shared/models"
LOGDIR="/workspace/shared/logs"
mkdir -p "$FORGE_DIR" "$SHARED_MODELS" "$LOGDIR"

# ---------- Clone Forge if missing ----------
if [ ! -d "$FORGE_DIR/.git" ]; then
  echo "[Setup] Cloning Forge WebUI..."
  git clone https://github.com/lllyasviel/stable-diffusion-webui-forge.git "$FORGE_DIR"
else
  echo "[Setup] Forge already present, pulling latest..."
  cd "$FORGE_DIR" && git pull && cd -
fi

# ---------- Symlink shared models ----------
ln -sf "$SHARED_MODELS" "$FORGE_DIR/models"
ln -sf "$SHARED_MODELS/checkpoints" "$FORGE_DIR/models/Stable-diffusion"
ln -sf "$SHARED_MODELS/vae" "$FORGE_DIR/models/VAE"
ln -sf "$SHARED_MODELS/loras" "$FORGE_DIR/models/Lora"
ln -sf "$SHARED_MODELS/embeddings" "$FORGE_DIR/embeddings"

# ---------- Dependencies ----------
cd "$FORGE_DIR"
echo "[Setup] Installing Forge dependencies..."
/opt/venv/bin/pip install --no-cache-dir -r requirements.txt || true

# ---------- Launch background services ----------
echo "[Start] Launching JupyterLab..."
nohup jupyter-lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root \
  > "$LOGDIR/jupyter.log" 2>&1 &

echo "[Start] Launching Forge WebUI..."
nohup python launch.py \
  --listen --server-name 0.0.0.0 --port 7860 \
  --xformers --api --skip-version-check \
  --disable-nan-check --no-half --no-half-vae \
  --enable-insecure-extension-access \
  --ckpt-dir "$SHARED_MODELS/checkpoints" \
  --vae-dir "$SHARED_MODELS/vae" \
  --lora-dir "$SHARED_MODELS/loras" \
  --embeddings-dir "$SHARED_MODELS/embeddings" \
  --controlnet-dir "$SHARED_MODELS/controlnet" \
  > "$LOGDIR/forge.log" 2>&1 &

# ---------- Final message ----------
sleep 5
echo "✅ Forge + Jupyter are running."
echo "   → Forge:   http://<pod-address>:7860"
echo "   → Jupyter: http://<pod-address>:8888/lab"
echo "Logs in: $LOGDIR"
echo "=============================================================="

# Keep container alive
tail -f /dev/null