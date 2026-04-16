#!/bin/bash
set -e

# Vast moze nie miec /workspace — stworz jesli brak
mkdir -p /workspace/models

WEIGHTS="${WEIGHTS_DIR:-/workspace/models}"
MARKER="$WEIGHTS/.download_complete"

export HF_TOKEN="${HF_TOKEN:-}"
export HF_HUB_ENABLE_HF_TRANSFER=1

# Activate venv if exists
[ -f /venv/main/bin/activate ] && . /venv/main/bin/activate

if [ -f "$MARKER" ]; then
  echo "[infinitetalk] Models cached. Ready."
  exit 0
fi

echo "[infinitetalk] First boot — downloading models (~85 GB)..."

# Try hf first (newer), fallback to huggingface-cli
DL_CMD="hf download"
$DL_CMD --help >/dev/null 2>&1 || DL_CMD="huggingface-cli download"

echo "[infinitetalk] 1/3 Wan 2.1 720P..."
$DL_CMD Wan-AI/Wan2.1-I2V-14B-720P --local-dir "$WEIGHTS/Wan2.1-I2V-14B-720P"

echo "[infinitetalk] 2/3 wav2vec2..."
$DL_CMD TencentGameMate/chinese-wav2vec2-base --local-dir "$WEIGHTS/chinese-wav2vec2-base"
$DL_CMD TencentGameMate/chinese-wav2vec2-base model.safetensors --revision refs/pr/1 --local-dir "$WEIGHTS/chinese-wav2vec2-base"

echo "[infinitetalk] 3/3 InfiniteTalk adapter..."
$DL_CMD MeiGen-AI/InfiniteTalk --include "single/*" --local-dir "$WEIGHTS/InfiniteTalk"

rm -rf ~/.cache/huggingface/hub
touch "$MARKER"
echo "[infinitetalk] All models downloaded. Ready to generate."
