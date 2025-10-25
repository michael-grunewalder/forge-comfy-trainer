#!/bin/bash
set -e
echo "=== Disabling Forge root check ==="
export COMMANDLINE_ARGS="--skip-root-check"

cd /workspace


# Persistent install of Forge
if [ ! -d "/workspace/forge" ]; then
    echo "=== First run: cloning Forge ==="
    git clone https://github.com/lllyasviel/stable-diffusion-webui-forge forge
    cd forge
    python -m venv venv
    source venv/bin/activate
    pip install --upgrade pip
    ./webui.sh --skip-torch-cuda-test --exit
else
    echo "=== Forge already present ==="
    cd forge
    source venv/bin/activate
fi

# Ensure shared model folder exists and link it
mkdir -p /workspace/models
if [ ! -L "/workspace/forge/models" ]; then
    rm -rf /workspace/forge/models
    ln -s /workspace/models /workspace/forge/models
fi

echo "=== Starting Forge on port 7860 ==="
#exec ./webui.sh --listen 0.0.0.0 --port 7860 --skip-torch-cuda-test
exec ./webui.sh --listen --port 7860 --skip-torch-cuda-test $COMMANDLINE_ARGS
