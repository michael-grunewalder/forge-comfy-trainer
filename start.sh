#!/usr/bin/env bash
set -euo pipefail

APP_VERSION="${APP_VERSION:-v1.0.5s}"
echo "=============================================================="
echo " 🧠  RunPod SD Environment"
echo "     Version: ${APP_VERSION}"
echo "     Boot:    $(date -u)"
echo "=============================================================="

# Shared dirs (idempotent)
mkdir -p /workspace/shared/{models,outputs,logs,datasets,checkpoints}
mkdir -p /workspace/shared/models/{checkpoints,loras,vae,clip,clip_vision,controlnet,upscale_models,embeddings}
mkdir -p /workspace/shared/outputs/{forge,comfyui,kohya}
mkdir -p /workspace/shared/logs/{forge,comfyui,jupyter,kohya}
mkdir -p /workspace/notebooks

export HF_HOME=/workspace/shared/huggingface
export PYTHONUNBUFFERED=1

# ---------- Forge ----------
(
  cd /opt/forge
  echo "🚀 Starting Forge..."
  # Exactly the flags your Forge build accepts (confirmed by your log).
  python launch.py \
    --listen \
    --server-name 0.0.0.0 \
    --port 7860 \
    --xformers \
    --api \
    --skip-version-check \
    --disable-nan-check \
    --gradio-queue \
    --no-half-vae \
    --enable-insecure-extension-access \
    --ckpt-dir /workspace/shared/models/checkpoints \
    --lora-dir /workspace/shared/models/loras \
    --vae-dir /workspace/shared/models/vae \
    --controlnet-dir /workspace/shared/models/controlnet \
    --embeddings-dir /workspace/shared/models/embeddings \
    --data-dir /workspace/shared \
  2>&1 | tee -a /workspace/shared/logs/forge/forge.log
) &

# ---------- ComfyUI ----------
(
  cd /opt/ComfyUI
  echo "🚀 Starting ComfyUI..."
  python main.py --listen 0.0.0.0 --port 8188 \
  2>&1 | tee -a /workspace/shared/logs/comfyui/comfyui.log
) &

# ---------- JupyterLab ----------
(
  cd /workspace
  echo "🚀 Starting JupyterLab..."
  jupyter lab \
    --ip=0.0.0.0 \
    --port=8888 \
    --no-browser \
    --allow-root \
    --IdentityProvider.token='' \
    --IdentityProvider.password_required=False \
    --ServerApp.token='' \
    --ServerApp.password='' \
    --ServerApp.base_url=/ \
    --ServerApp.root_dir=/workspace \
    --ServerApp.trust_xheaders=True \
    --ServerApp.allow_origin='*' \
    --ServerApp.allow_remote_access=True \
    --ServerApp.disable_check_xsrf=True \
    --ServerApp.use_redirect_file=False \
    --ServerApp.tornado_settings='{"headers":{"Content-Security-Policy":""}}' \
    --NotebookApp.default_url='/lab' \
    --ServerApp.terminado_settings='{"shell_command":["/bin/bash"]}' \
  2>&1 | tee -a /workspace/shared/logs/jupyter/jupyter.log
) &

# ---------- Log tail ----------
sleep 2
echo "=============================================================="
echo "Forge:     http://localhost:7860"
echo "ComfyUI:   http://localhost:8188"
echo "Jupyter:   http://localhost:8888"
echo "=============================================================="

tail -F \
  /workspace/shared/logs/forge/forge.log \
  /workspace/shared/logs/comfyui/comfyui.log \
  /workspace/shared/logs/jupyter/jupyter.log