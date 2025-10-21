#!/bin/bash
set -e

# Ensure base dirs exist
mkdir -p /workspace/{models,outputs,notebooks,forge,comfyui,train}

# Link shared model folder into each app
ln -sf /workspace/models /workspace/forge/models
ln -sf /workspace/models /workspace/comfyui/models
ln -sf /workspace/models /workspace/train/models

# Optional model preload
#if [ ! -f /workspace/models/sd_xl_base_1.0.safetensors ]; then
#    echo "Downloading SDXL base model..."
#    wget -q -O /workspace/models/sd_xl_base_1.0.safetensors \
#        "https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors?download=true"
#fi

# Forge
if [ -d /workspace/forge ]; then
    cd /workspace/forge
    nohup python launch.py --listen 0.0.0.0 --port 7860 --enable-insecure-extension-access \
        > /workspace/forge.log 2>&1 &
else
    echo "⚠️ Forge directory not found, skipping Forge startup"
fi

# ComfyUI
if [ -d /workspace/comfyui ]; then
    cd /workspace/comfyui
    nohup python main.py --listen 0.0.0.0 --port 8188 \
        > /workspace/comfyui.log 2>&1 &
else
    echo "⚠️ ComfyUI directory not found, skipping ComfyUI startup"
fi

# TensorBoard
mkdir -p /workspace/train/logs
cd /workspace/train
nohup tensorboard --logdir logs --host 0.0.0.0 --port 6006 \
    > /workspace/tensorboard.log 2>&1 &

# JupyterLab (Notebook)
mkdir -p /workspace/notebooks
cd /workspace/notebooks
nohup jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root \
    --NotebookApp.token="${JUPYTER_TOKEN:-runpod}" \
    > /workspace/jupyter.log 2>&1 &

# Keep container alive
tail -f /dev/null