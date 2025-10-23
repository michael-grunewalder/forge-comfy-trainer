#!/usr/bin/env bash
set -euo pipefail

BUILD_DATE="$(date -u +'%Y-%m-%d %H:%M:%S UTC')"
VERSION="${APP_VERSION:-v1.0.s}"


echo "=============================================================="
echo " 🧠  Bearny's AI Lab"
echo "=============================================================="
echo "[Info] Version ${VERSION}"
echo "[Boot] ${BUILD_DATE}"
echo "=============================================================="

# ---------- Paths ----------
VENV="/workspace/venv"
LOGDIR="/workspace/shared/logs"
APPS_DIR="/workspace/apps"

mkdir -p "$LOGDIR" \
         "$APPS_DIR" \
         /workspace/shared/{models,outputs,configs} \
         /workspace/shared/models/{checkpoints,vae,loras,controlnet,embeddings}

# ---------- Virtualenv (persistent across pods) ----------
if [ ! -x "$VENV/bin/pip" ]; then
  echo "[Setup] Creating Python virtualenv at $VENV ..."
  python3 -m venv "$VENV"
  "$VENV/bin/pip" install --upgrade pip setuptools wheel
else
  echo "[Setup] Reusing existing virtualenv (cached from previous run)"
fi

PIP="$VENV/bin/pip"
PY="$VENV/bin/python"

# ---------- Base dependencies ----------
echo "[Setup] Ensuring core dependencies are installed..."
$PIP install --no-cache-dir --upgrade \
  torch==2.4.1+cu121 torchvision==0.19.1+cu121 torchaudio==2.4.1+cu121 \
  --index-url https://download.pytorch.org/whl/cu121

$PIP install --no-cache-dir --upgrade \
  xformers==0.0.27.post2 gradio==4.36.1 fastapi uvicorn jupyterlab==4.2.5 \
  einops safetensors opencv-python pillow tqdm bitsandbytes accelerate

# ---------- Forge ----------
FORGE_DIR="$APPS_DIR/forge"
if [ ! -d "$FORGE_DIR/.git" ]; then
  echo "[Setup] Installing Forge..."
  git clone --depth=1 https://github.com/lllyasviel/stable-diffusion-webui-forge.git "$FORGE_DIR"
  if [ -f "$FORGE_DIR/requirements.txt" ]; then
    $PIP install --no-cache-dir -r "$FORGE_DIR/requirements.txt" || true
  fi
else
  echo "[Setup] Forge already installed."
fi

# ---------- ComfyUI ----------
COMFY_DIR="$APPS_DIR/ComfyUI"
if [ ! -d "$COMFY_DIR/.git" ]; then
  echo "[Setup] Installing ComfyUI..."
  git clone --depth=1 https://github.com/comfyanonymous/ComfyUI.git "$COMFY_DIR"
  if [ -f "$COMFY_DIR/requirements.txt" ]; then
    $PIP install --no-cache-dir -r "$COMFY_DIR/requirements.txt" || true
  fi
else
  echo "[Setup] ComfyUI already installed."
fi

# ---------- ComfyUI Manager ----------
MANAGER_DIR="$COMFY_DIR/custom_nodes/ComfyUI-Manager"
if [ ! -d "$MANAGER_DIR/.git" ]; then
  echo "[Setup] Installing ComfyUI Manager..."
  git clone --depth=1 https://github.com/ltdrdata/ComfyUI-Manager.git "$MANAGER_DIR"
fi

# ---------- kohya_ss (optional) ----------
KOHYA_DIR="$APPS_DIR/kohya_ss"
if [ ! -d "$KOHYA_DIR/.git" ]; then
  echo "[Setup] Installing kohya_ss..."
  git clone --depth=1 https://github.com/bmaltais/kohya_ss.git "$KOHYA_DIR"
fi

# ---------- Launch services ----------
echo "--------------------------------------------------------------"
echo "[Launch] Starting services..."
echo "--------------------------------------------------------------"

# JupyterLab
nohup "$PY" -m jupyterlab --ip=0.0.0.0 --port=8888 --no-browser \
  --NotebookApp.token='' --NotebookApp.password='' \
  > "$LOGDIR/jupyter.log" 2>&1 &

# ComfyUI
cd "$COMFY_DIR"
nohup "$PY" main.py --listen 0.0.0.0 --port 8188 \
  > "$LOGDIR/comfyui.log" 2>&1 &

# Forge
cd "$FORGE_DIR"
nohup "$PY" launch.py \
  --listen --server-name 0.0.0.0 --port 7860 \
  --xformers --api --skip-version-check --disable-nan-check \
  --no-half --no-half-vae --enable-insecure-extension-access \
  --ckpt-dir /workspace/shared/models/checkpoints \
  --vae-dir /workspace/shared/models/vae \
  --lora-dir /workspace/shared/models/loras \
  --embeddings-dir /workspace/shared/models/embeddings \
  --controlnet-dir /workspace/shared/models/controlnet \
  --data-dir /workspace/shared/configs \
  > "$LOGDIR/forge.log" 2>&1 &

# kohya_ss
cd "$KOHYA_DIR"
nohup "$PY" kohya_gui.py --listen 0.0.0.0 --server_port 7861 \
  > "$LOGDIR/kohya.log" 2>&1 &

# ---------- Completion Banner ----------
echo "=============================================================="
echo " ✅ Bearny's AI Lab setup complete!"
echo "--------------------------------------------------------------"
echo " Services running:"
echo "   • Forge      : http://0.0.0.0:7860"
echo "   • kohya_ss   : http://0.0.0.0:7861"
echo "   • ComfyUI    : http://0.0.0.0:8188"
echo "   • JupyterLab : http://0.0.0.0:8888"
echo "--------------------------------------------------------------"
echo " Logs in: $LOGDIR"
echo " Virtualenv: $VENV (persistent between pods)"
echo "=============================================================="

tail -n 25 -f "$LOGDIR"/*.log