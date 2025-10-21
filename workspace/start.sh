#!/bin/bash
# Launch everything in background and keep container alive
cd /workspace/forge && python launch.py --listen --port 7860 &
cd /workspace/ComfyUI && python main.py --listen 0.0.0.0 --port 8188 &
tensorboard --logdir /workspace/train/logs --port 6006 &
jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root --NotebookApp.token=${JUPYTER_TOKEN:-runpod}

