#!/bin/bash
set -e

mkdir -p /workspace/{models,outputs,notebooks}

ln -sf /workspace/models /workspace/forge/models
ln -sf /workspace/models /workspace/comfyui/models
ln -sf /workspace/models /workspace/train/models

# Optional model preload
if [ ! -f /workspace/models/sd_xl_base_1.0.safetensors ]; then
    echo "Downloading SDXL base model..."
    wget -q -O /workspace/models/sd_xl_base_1.0.safetensors \
        https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors?download=true
fi

# Forge
cd /workspace/forge
nohup python launch.py --listen 0.0.0.0 --port 7860 --enable-insecure-extension-access \
    > /workspace/forge.log 2>&1 &

# ComfyUI
cd /workspace/comfyui
nohup python main.py --listen 0.0.0.0 --port 8188 \
    > /workspace/comfyui.log 2>&1 &

# TensorBoard
cd /workspace/train
nohup tensorboard --logdir logs --host 0.0.0.0 --port 6006 \
    > /workspace/tensorboard.log 2>&1 &

# JupyterLab (Notebook)
cd /workspace/notebooks
nohup jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --NotebookApp.token="$JUPYTER_TOKEN" \
    > /workspace/jupyter.log 2>&1 &

tail -f /dev/null
