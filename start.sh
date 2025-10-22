#!/usr/bin/env bash
set -euo pipefail

# ===== Version banner =====
echo "=============================================================="
echo " 🧠  RunPod SD Environment"
echo "     Version: ${APP_VERSION}"
echo "     Boot:    $(date -u)"
echo "=============================================================="

# ===== Shared dirs =====
mkdir -p /workspace/shared/{models,outputs,logs,datasets,checkpoints}
mkdir -p /workspace/shared/models/{checkpoints,loras,vae,clip,clip_vision,controlnet,upscale_models,embeddings}
mkdir -p /workspace/shared/outputs/{forge,comfyui,kohya}
mkdir -p /workspace/shared/logs/{forge,comfyui,jupyter,kohya}
mkdir -p /workspace/notebooks

export HF_HOME=/workspace/shared/huggingface
export PYTHONUNBUFFERED=1

# ===== NO dummy checkpoints =====
# Forge can start without a checkpoint; a fake .safetensors breaks metadata parsing.
# Put a real model into /workspace/shared/models/checkpoints to actually generate.

# ===== Forge (A1111/Forge) =====
(
  cd /opt/forge
  echo "🚀 Starting Forge..."
  # Notes:
  # - --outputs-dir REMOVED (not supported by current Forge)
  # - --gradio-auth REMOVED (bad value 'none' crashed gradio)
  # - --data-dir points Forge at /workspace/shared for config/cache/outputs
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

# ===== ComfyUI =====
(
  cd /opt/ComfyUI
  echo "🚀 Starting ComfyUI..."
  python main.py --listen 0.0.0.0 --port 8188 \
  2>&1 | tee -a /workspace/shared/logs/comfyui/comfyui.log
) &

# ===== JupyterLab =====
(
  cd /workspace
  echo "🚀 Starting JupyterLab..."
  # The proxy-white-screen was a CSP/XSRF mismatch. These flags fix it under RunPod’s proxy.
  jupyter lab \
    --ip=0.0.0.0 \
    --port=8888 \
    --no-browser \
    --allow-root \
    --ServerApp.base_url=/ \
    --ServerApp.trust_xheaders=True \
    --ServerApp.allow_origin='*' \
    --ServerApp.use_redirect_file=False \
    --ServerApp.disable_check_xsrf=True \
    --ServerApp.token='' \
    --ServerApp.password='' \
    --ServerApp.terminado_settings='{"shell_command":["/bin/bash"]}' \
    --NotebookApp.default_url='/lab' \
    --ServerApp.tornado_settings='{"headers":{"Content-Security-Policy":""}}' \
  2>&1 | tee -a /workspace/shared/logs/jupyter/jupyter.log
) &

# ===== UX =====
sleep 2
echo "=============================================================="
echo "Forge:     http://localhost:7860"
echo "ComfyUI:   http://localhost:8188"
echo "Jupyter:   http://localhost:8888"
echo "=============================================================="

tail -F /workspace/shared/logs/forge/forge.log \
       /workspace/shared/logs/comfyui/comfyui.log \
       /workspace/shared/logs/jupyter/jupyter.log