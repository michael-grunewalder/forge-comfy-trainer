#!/usr/bin/env bash
set -euo pipefail

BUILD_DATE="$(date -u +'%Y-%m-%d %H:%M:%S UTC')"
VERSION="${APP_VERSION:-v1.0.1s}"

echo "=============================================================="
echo " 🧠  Bearny's AI Lab"
echo "=============================================================="
echo "[Info] Version ${VERSION}"
echo "[Boot] ${BUILD_DATE}"
echo "=============================================================="

# ---------- Directories ----------
VENV="/opt/venv"
LOGDIR="/workspace/shared/logs"
mkdir -p "$LOGDIR"

APPS_DIR="/workspace/apps"
mkdir -p "$APPS_DIR" \
  /workspace/shared/{models,outputs,configs} \
  /workspace/shared/models/{checkpoints,vae,loras,controlnet,embeddings}

# ---------- Create virtualenv if missing ----------
if [ ! -x "$VENV/bin/pip" ]; then
  echo "[Setup] Creating Python virtualenv..."
  python3 -m venv "$VENV" || { echo "[Error] Could not create venv"; exit 1; }
  "$VENV/bin/pip" install --upgrade pip setuptools wheel
fi

PIP="$VENV/bin/pip"
PY="$VENV/bin/python"

# ---------- Install/upgrade core deps ----------
echo "[Setup] Installing/Updating base Python packages..."
$PIP install --no-cache-dir \
  --index-url https://download.pytorch.org/whl/cu121 \
  torch==2.4.1+cu121 torchvision==0.19.1+cu121 torchaudio==2.4.1+cu121

$PIP install --no-cache-dir xformers==0.0.27.post2 \
  gradio==4.36.1 fastapi uvicorn jupyterlab==4.2.5 einops safetensors \
  opencv-python pillow tqdm bitsandbytes accelerate

# ---------- Version control banner ----------
echo "[Setup] Environment ready – Python: $(python3 --version)"
echo "[Setup] PIP path: $PIP"
echo "[Setup] Apps directory: $APPS_DIR"

UPDATE_ON_START=${UPDATE_ON_START:-false}

# ---------- Install Forge ----------
FORGE_DIR="$APPS_DIR/forge"
if [ ! -d "$FORGE_DIR/.git" ]; then
  echo "[Setup] Installing Forge into $FORGE_DIR ..."
  git clone --depth=1 https://github.com/lllyasviel/stable-diffusion-webui-forge.git "$FORGE_DIR"
else
  echo "[Setup] Forge found."
  if [ "$UPDATE_ON_START" = "true" ]; then
    echo "[Update] Pulling Forge..."
    (cd "$FORGE_DIR" && git pull --rebase || true)
  fi
fi

if [ -f "$FORGE_DIR/requirements_versions.txt" ]; then
  $PIP install --no-cache-dir -r "$FORGE_DIR/requirements_versions.txt" || true
fi
if [ -f "$FORGE_DIR/requirements.txt" ]; then
  $PIP install --no-cache-dir -r "$FORGE_DIR/requirements.txt" || true
fi

# ---------- Install ComfyUI & Manager ----------
COMFY_DIR="$APPS_DIR/ComfyUI"
if [ ! -d "$COMFY_DIR/.git" ]; then
  echo "[Setup] Installing ComfyUI..."
  git clone --depth=1 https://github.com/comfyanonymous/ComfyUI.git "$COMFY_DIR"
  if [ -f "$COMFY_DIR/requirements.txt" ]; then
    $PIP install --no-cache-dir -r "$COMFY_DIR/requirements.txt" || true
  fi
else
  if [ "$UPDATE_ON_START" = "true" ]; then
    (cd "$COMFY_DIR" && git pull --rebase || true)
  fi
fi

MANAGER_DIR="$COMFY_DIR/custom_nodes/ComfyUI-Manager"
if [ ! -d "$MANAGER_DIR/.git" ]; then
  git clone --depth=1 https://github.com/ltdrdata/ComfyUI-Manager.git "$MANAGER_DIR"
fi

# ---------- Launch services ----------
echo "[Launch] Starting JupyterLab on :8888"
nohup "$PY" -m jupyterlab --ip=0.0.0.0 --port=8888 --no-browser \
      --NotebookApp.token='' --NotebookApp.password='' \
      > "$LOGDIR/jupyter.log" 2>&1 &

echo "[Launch] Starting ComfyUI on :8188"
cd "$COMFY_DIR"
nohup "$PY" main.py --listen 0.0.0.0 --port 8188 \
      > "$LOGDIR/comfyui.log" 2>&1 &

echo "[Launch] Starting Forge on :7860"
cd "$FORGE_DIR"
exec "$PY" launch.py \
  --listen --server-name 0.0.0.0 --port 7860 \
  --xformers \
  --api \
  --skip-version-check \
  --disable-nan-check \
  --no-half --no-half-vae \
  --enable-insecure-extension-access \
  --ckpt-dir /workspace/shared/models/checkpoints \
  --vae-dir /workspace/shared/models/vae \
  --lora-dir /workspace/shared/models/loras \
  --embeddings-dir /workspace/shared/models/embeddings \
  --controlnet-dir /workspace/shared/models/controlnet \
  --data-dir /workspace/shared/configs \
  2>&1 | tee -a "$LOGDIR/forge.log"