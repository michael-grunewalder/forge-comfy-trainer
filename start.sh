#!/usr/bin/env bash
set -euo pipefail

# Make sure shared dirs exist even if /workspace is a fresh volume
mkdir -p /workspace/shared/{models,outputs,logs,datasets,checkpoints}
mkdir -p /workspace/shared/models/{checkpoints,loras,vae,clip,clip_vision,controlnet,upscale_models,embeddings}
mkdir -p /workspace/shared/outputs/{forge,comfyui,kohya}
mkdir -p /workspace/shared/logs/{forge,comfyui,jupyter,kohya}
mkdir -p /workspace/notebooks

# Helpful env
export HF_HOME=/workspace/shared/huggingface
export PYTHONUNBUFFERED=1

# ---- Symlinks so everyone shares the same asset folders ----

# Forge
if [ ! -L /opt/forge/models/Stable-diffusion ]; then
  mkdir -p /opt/forge/models
  ln -sf /workspace/shared/models/checkpoints /opt/forge/models/Stable-diffusion
fi
ln -sf /workspace/shared/models/vae        /opt/forge/models/VAE
ln -sf /workspace/shared/models/loras      /opt/forge/models/Lora
# (optional) embeddings
mkdir -p /opt/forge/embeddings
ln -sf /workspace/shared/models/embeddings /opt/forge/embeddings
# outputs
rm -rf /opt/forge/outputs
ln -sf /workspace/shared/outputs/forge /opt/forge/outputs

# ComfyUI
mkdir -p /opt/ComfyUI/models
ln -sf /workspace/shared/models/checkpoints   /opt/ComfyUI/models/checkpoints
ln -sf /workspace/shared/models/loras         /opt/ComfyUI/models/loras
ln -sf /workspace/shared/models/vae           /opt/ComfyUI/models/vae
ln -sf /workspace/shared/models/clip          /opt/ComfyUI/models/clip
ln -sf /workspace/shared/models/clip_vision   /opt/ComfyUI/models/clip_vision
ln -sf /workspace/shared/models/controlnet    /opt/ComfyUI/models/controlnet
ln -sf /workspace/shared/models/upscale_models /opt/ComfyUI/models/upscale_models
ln -sf /workspace/shared/models/embeddings    /opt/ComfyUI/models/embeddings
rm -rf /opt/ComfyUI/output
ln -sf /workspace/shared/outputs/comfyui /opt/ComfyUI/output

# kohya_ss will consume whatever paths you pass; use shared datasets/outputs by convention
mkdir -p /workspace/shared/datasets /workspace/shared/checkpoints /workspace/shared/outputs/kohya

# ---- Launch services ----

# 1) Forge (A1111/Forge) on 7860
# --- Forge: use shared models directly ---
export FORGE_MODEL_DIR="/workspace/shared/models"
export FORGE_OUTPUT_DIR="/workspace/shared/outputs/forge"
export FORGE_EMBEDDINGS_DIR="/workspace/shared/models/embeddings"

# Ensure subfolders exist so Forge doesn’t recreate /opt paths
mkdir -p \
  /workspace/shared/models/{checkpoints,loras,vae,controlnet,upscale_models,embeddings} \
  /workspace/shared/outputs/forge

# Run Forge using shared dirs directly
(
  cd /opt/forge
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
    --outputs-dir /workspace/shared/outputs/forge \
    2>&1 | tee -a /workspace/shared/logs/forge/forge.log
) &

# 2) ComfyUI on 8188
(
  cd /opt/ComfyUI
  python main.py --listen 0.0.0.0 --port 8188 \
  2>&1 | tee -a /workspace/shared/logs/comfyui/comfyui.log
) &

# 3) JupyterLab on 8888 (no token, runs in /workspace)
(
  cd /workspace
  jupyter lab \
  --ip=0.0.0.0 \
  --port=8888 \
  --no-browser \
  --allow-root \
  --ServerApp.token='' \
  --ServerApp.password='' \
  --ServerApp.terminado_settings='{"shell_command":["/bin/bash"]}' \
  --NotebookApp.default_url='/lab' \
  2>&1 | tee -a /workspace/shared/logs/jupyter/jupyter.log
) &

# Optional: TensorBoard (commented; uncomment if you want port 6006)
# (
#   mkdir -p /workspace/shared/logs/tensorboard
#   tensorboard --logdir /workspace/shared/logs/tensorboard --host 0.0.0.0 --port 6006 \
#   2>&1 | tee -a /workspace/shared/logs/jupyter/tensorboard.log
# ) &

# Keep container alive; show combined logs tail
sleep 2
echo "Forge:     http://localhost:7860"
echo "ComfyUI:   http://localhost:8188"
echo "Jupyter:   http://localhost:8888"
tail -F /workspace/shared/logs/forge/forge.log \
       /workspace/shared/logs/comfyui/comfyui.log \
       /workspace/shared/logs/jupyter/jupyter.log
