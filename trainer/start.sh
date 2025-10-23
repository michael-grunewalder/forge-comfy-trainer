#!/usr/bin/env bash
set -e

# ==============================================================
# 🧠  Bearny's AI Lab - Trainer Node
# ==============================================================

BUILD_DATE="$(date -u +'%Y-%m-%d %H:%M:%S UTC')"
VERSION="${APP_VERSION:-v1.0.0}"
echo "=============================================================="
echo " 🧠  Bearny's AI Lab - Trainer Node"
echo "     Version: $VERSION"
echo "     Build:   $BUILD_DATE"
echo "=============================================================="

# ---------- Directories ----------
TRAINER_DIR="/workspace/trainer"
SHARED_MODELS="/workspace/shared/models"
LOGDIR="/workspace/shared/logs"
mkdir -p "$TRAINER_DIR" "$SHARED_MODELS" "$LOGDIR"

# ---------- Clone KohyaSS if missing ----------
if [ ! -d "$TRAINER_DIR/.git" ]; then
  echo "[Setup] Cloning KohyaSS GUI..."
  git clone https://github.com/bmaltais/kohya_ss.git "$TRAINER_DIR"
else
  echo "[Setup] KohyaSS already present, pulling latest..."
  cd "$TRAINER_DIR" && git pull && cd -
fi

# ---------- Symlink shared models ----------
ln -sf "$SHARED_MODELS" "$TRAINER_DIR/models"
ln -sf "$SHARED_MODELS/checkpoints" "$TRAINER_DIR/pretrained_models"
ln -sf "$SHARED_MODELS/vae" "$TRAINER_DIR/vae"
ln -sf "$SHARED_MODELS/loras" "$TRAINER_DIR/output"

# ---------- Dependencies ----------
cd "$TRAINER_DIR"
echo "[Setup] Installing KohyaSS dependencies..."
/opt/venv/bin/pip install --no-cache-dir -r requirements.txt || true

# ---------- Launch background services ----------
echo "[Start] Launching JupyterLab..."
nohup jupyter-lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root \
  > "$LOGDIR/jupyter.log" 2>&1 &

echo "[Start] Launching KohyaSS WebUI..."
nohup python kohya_gui.py --listen 0.0.0.0 --port 7861 > "$LOGDIR/trainer.log" 2>&1 &

# ---------- Final message ----------
sleep 5
echo "✅ KohyaSS Trainer + Jupyter are running."
echo "   → Trainer: http://<pod-address>:7861"
echo "   → Jupyter: http://<pod-address>:8888/lab"
echo "Logs in: $LOGDIR"
echo "=============================================================="

tail -f /dev/null
