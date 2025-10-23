#!/usr/bin/env bash
set -euo pipefail

# ===========================================================
# 🧠  Bearny's AI Lab Startup Script
# ===========================================================
APP_VERSION="${APP_VERSION:-v1.0.3s}"
BUILD_DATE="$(date -u +'%Y-%m-%d %H:%M:%S UTC')"

echo "=============================================================="
echo " 🧠  Bearny's AI Lab booting..."
echo "     Version: ${APP_VERSION}"
echo "     Build:   ${BUILD_DATE}"
echo "=============================================================="

# === Paths ====================================================
VENV_DIR="/workspace/venv"
TOOLS_DIR="/workspace/tools"
SHARED="/workspace/shared"
LOGS_DIR="${SHARED}/logs"
mkdir -p "${LOGS_DIR}" "${TOOLS_DIR}"

# === Prepare venv =============================================
echo "[Setup] Checking Python environment..."
if [ ! -d "$VENV_DIR" ]; then
    echo "[Setup] Creating venv at $VENV_DIR..."
    python3 -m venv "$VENV_DIR"
fi

source "$VENV_DIR/bin/activate"

echo "[Setup] Upgrading base tools..."
pip install -q --upgrade pip setuptools wheel

# === Ensure Core Packages =====================================
echo "[Setup] Ensuring essential Python libs..."
pip install -q numpy==1.26.4 scipy==1.12.0 \
    torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
pip install -q xformers==0.0.27.post2 jupyterlab==4.2.5 gradio==4.44.0 \
    fastapi uvicorn einops opencv-python pillow==10.2.0 tqdm safetensors \
    accelerate==0.34.2 bitsandbytes==0.45.3 pycairo tensorboard==2.17.1 joblib

# ===========================================================
# 🧩 Install CivitAI downloader (persistent across Pods)
# ===========================================================
DL_SCRIPT="${TOOLS_DIR}/civitai-download.sh"
BIN_LINK="/usr/local/bin/civitai-download"

if [ ! -f "$DL_SCRIPT" ]; then
    echo "[Setup] Installing CivitAI downloader..."
    cat <<'EOF' > "$DL_SCRIPT"
#!/usr/bin/env bash
set -euo pipefail

API_BASE="https://civitai.com/api/v1/models"
SHARED="/workspace/shared/models"

if [ -z "${1:-}" ]; then
  echo "Usage: $0 <MODEL_ID>"
  exit 1
fi
MODEL_ID="$1"

if [ -z "${CIVITAI_TOKEN:-}" ]; then
  echo "❌ Please set CIVITAI_TOKEN first:"
  echo "   export CIVITAI_TOKEN='your_token_here'"
  exit 1
fi

echo "🔍 Fetching metadata for model $MODEL_ID ..."
JSON=$(curl -sSf -H "Authorization: Bearer ${CIVITAI_TOKEN}" "${API_BASE}/${MODEL_ID}" || echo "")

if [ -z "$JSON" ]; then
  echo "❌ Failed to fetch metadata. Check your network or token."
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "Installing jq..."
  apt-get update -qq && apt-get install -y -qq jq
fi

TYPE=$(echo "$JSON" | jq -r '.type' | tr '[:upper:]' '[:lower:]')
NAME=$(echo "$JSON" | jq -r '.name' | tr ' /' '_-')
VERSION_ID=$(echo "$JSON" | jq -r '.modelVersions[0].id')

if [ -z "$VERSION_ID" ] || [ "$VERSION_ID" = "null" ]; then
  echo "❌ Could not determine model version ID."
  echo "$JSON"
  exit 1
fi

DL_URL="https://civitai.com/api/download/models/${VERSION_ID}?type=Model&format=SafeTensor&size=full&fp=fp16"

case "$TYPE" in
  checkpoint|model|sdxl|sd1|sd2|flux) TARGET="${SHARED}/checkpoints" ;;
  lora|lycoris) TARGET="${SHARED}/loras" ;;
  vae) TARGET="${SHARED}/vae" ;;
  embedding|textual_inversion) TARGET="${SHARED}/embeddings" ;;
  controlnet) TARGET="${SHARED}/controlnet" ;;
  *) TARGET="${SHARED}/others" ;;
esac

mkdir -p "$TARGET"
FILENAME="${NAME}_${VERSION_ID}.safetensors"
OUTPATH="${TARGET}/${FILENAME}"

echo "📦 Model: $NAME"
echo "📁 Type: $TYPE"
echo "🌐 Download: $DL_URL"
echo "💾 Saving to: $OUTPATH"

curl -L -C - \
  -H "Authorization: Bearer ${CIVITAI_TOKEN}" \
  -o "$OUTPATH" \
  "$DL_URL"

echo "✅ Done! Saved to $OUTPATH"
EOF

    chmod +x "$DL_SCRIPT"
    ln -sf "$DL_SCRIPT" "$BIN_LINK"
    echo "[OK] CivitAI downloader installed at $DL_SCRIPT"
else
    echo "[Skip] CivitAI downloader already exists."
fi

# ===========================================================
# 🧠  Start Applications
# ===========================================================
echo "[Startup] Preparing applications..."

# --- ComfyUI --------------------------------------------------
COMFY_DIR="/workspace/apps/ComfyUI"
COMFY_MODELS="${COMFY_DIR}/models"
SHARED_MODELS="/workspace/shared/models"

if [ -d "$COMFY_DIR" ]; then
    echo "[ComfyUI] Ensuring shared model links..."
    mkdir -p "$SHARED_MODELS"

    if [ -d "$COMFY_MODELS" ] && [ ! -L "$COMFY_MODELS" ]; then
        echo "[ComfyUI] Replacing local models/ folder with symlink..."
        rm -rf "$COMFY_MODELS"
    fi

    if [ ! -L "$COMFY_MODELS" ]; then
        ln -s "$SHARED_MODELS" "$COMFY_MODELS"
    fi

    echo "[ComfyUI] Launching..."
    cd "$COMFY_DIR"
    nohup python main.py --listen 0.0.0.0 --port 8188 > "${LOGS_DIR}/comfyui.log" 2>&1 &
else
    echo "[ComfyUI] Directory missing, skipping."
fi

# --- Jupyter --------------------------------------------------
echo "[JupyterLab] Launching..."
mkdir -p "${LOGS_DIR}/jupyter"
nohup jupyter-lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root > "${LOGS_DIR}/jupyter/jupyter.log" 2>&1 &

# ===========================================================
# 🧩 Forge Auto-repair and Launch
# ===========================================================
FORGE_DIR="/workspace/apps/forge"
mkdir -p "${LOGS_DIR}/forge"
echo "[Forge] Preparing environment..."

if [ -d "$FORGE_DIR" ]; then
    cd "$FORGE_DIR"
    echo "[Forge] Repairing dependencies..."
    pip install -q joblib numpy==1.26.4 bitsandbytes==0.45.3 accelerate==0.34.2 safetensors==0.4.3

    GOOD_COMMIT="dfdcbab685e57677014f05a3309b48cc87383167"
    git fetch origin || true
    git reset --hard "$GOOD_COMMIT" || true

    echo "[Forge] Launching..."
    nohup python launch.py \
      --listen \
      --server-name 0.0.0.0 \
      --port 7860 \
      --xformers \
      --api \
      --skip-version-check \
      --disable-nan-check \
      --no-half \
      --no-half-vae \
      --enable-insecure-extension-access \
      --ckpt-dir /workspace/shared/models/checkpoints \
      --vae-dir /workspace/shared/models/vae \
      --lora-dir /workspace/shared/models/loras \
      --embeddings-dir /workspace/shared/models/embeddings \
      --controlnet-dir /workspace/shared/models/controlnet \
      --data-dir /workspace/shared/configs \
      > "${LOGS_DIR}/forge/forge_autostart.log" 2>&1 &
else
    echo "[Forge] Directory missing, skipping launch."
fi

# ===========================================================
# ✅ Final confirmation
# ===========================================================
echo "=============================================================="
echo "✅ All startup installations complete!"
echo "   Forge, ComfyUI, and JupyterLab are now launching."
echo "   Logs available under: ${LOGS_DIR}/"
echo
echo "💡 To fetch models directly:"
echo "      civitai-download <model_id>"
echo
echo "🕓 Wait until you see Forge UI on port 7860 and ComfyUI on 8188."
echo "=============================================================="
