#!/usr/bin/env bash
set -euo pipefail
echo "=============================================================="
echo " 🧠  BEARNY#s AI LAB"
echo "     Version:  ${APP_VERSION:-unknown}"
echo "     Built: $(date -u)"
echo "=============================================================="
sleep 1

# --- Ensure shared directories exist ---
mkdir -p /workspace/shared/{models,outputs,logs,datasets,checkpoints}
mkdir -p /workspace/shared/models/{checkpoints,loras,vae,clip,clip_vision,controlnet,upscale_models,embeddings}
mkdir -p /workspace/shared/outputs/{forge,comfyui,kohya}
mkdir -p /workspace/shared/logs/{forge,comfyui,jupyter,kohya}
mkdir -p /workspace/notebooks

export HF_HOME=/workspace/shared/huggingface
export PYTHONUNBUFFERED=1

# --- Dummy checkpoint to pass readiness ---
if ! ls /workspace/shared/models/checkpoints/*.{safetensors,ckpt} >/dev/null 2>&1; then
  echo "⚠️ No model found in /workspace/shared/models/checkpoints; creating dummy.safetensors"
  touch /workspace/shared/models/checkpoints/dummy.safetensors
fi

# --- Launch Forge (Stable-Diffusion-WebUI-Forge) ---
(
  cd /opt/forge
  echo "🚀 Starting Forge..."
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
  --gradio-auth none \
  --ckpt-dir /workspace/shared/models/checkpoints \
  --lora-dir /workspace/shared/models/loras \
  --vae-dir /workspace/shared/models/vae \
  --controlnet-dir /workspace/shared/models/controlnet \
  --embeddings-dir /workspace/shared/models/embeddings \
  --data-dir /workspace/shared \
  2>&1 | tee -a /workspace/shared/logs/forge/forge.log
) &

# --- Launch ComfyUI ---
(
  cd /opt/ComfyUI
  echo "🚀 Starting ComfyUI..."
  python main.py --listen 0.0.0.0 --port 8188 \
  2>&1 | tee -a /workspace/shared/logs/comfyui/comfyui.log
) &

# --- Launch JupyterLab ---
(
  cd /workspace
  echo "🚀 Starting JupyterLab..."
  jupyter lab \
  --ip=0.0.0.0 \
  --port=8888 \
  --no-browser \
  --allow-root \
  --ServerApp.base_url=/ \
  --ServerApp.use_redirect_file=False \
  --ServerApp.disable_check_xsrf=True \
  --ServerApp.token='' \
  --ServerApp.password='' \
  --ServerApp.terminado_settings='{"shell_command":["/bin/bash"]}' \
  --NotebookApp.default_url='/lab' \
  2>&1 | tee -a /workspace/shared/logs/jupyter/jupyter.log
) &

# --- Tail logs for visibility ---
sleep 2
echo "=============================================================="
echo "Forge:     http://localhost:7860"
echo "ComfyUI:   http://localhost:8188"
echo "Jupyter:   http://localhost:8888"
echo "=============================================================="

tail -F /workspace/shared/logs/forge/forge.log \
       /workspace/shared/logs/comfyui/comfyui.log \
       /workspace/shared/logs/jupyter/jupyter.log