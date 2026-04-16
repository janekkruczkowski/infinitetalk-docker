#!/bin/bash
# Auto-download models + setup — runs at boot
set -e

WEIGHTS="${WEIGHTS_DIR:-/workspace/models}"
MARKER="$WEIGHTS/.download_complete"

export HF_TOKEN="${HF_TOKEN:-}"
export HF_HUB_ENABLE_HF_TRANSFER=1

# Activate venv (works for both vast and runpod bases)
[ -f /venv/main/bin/activate ] && . /venv/main/bin/activate

echo "[infinitetalk] Checking models in $WEIGHTS..."

if [ -f "$MARKER" ]; then
  echo "[infinitetalk] Models already downloaded. Ready."
  exit 0
fi

echo "[infinitetalk] Downloading models (~85 GB)..."
mkdir -p "$WEIGHTS"

pip install -U huggingface_hub hf_transfer 2>/dev/null || true

echo "[infinitetalk] 1/3 Wan 2.1 I2V 14B 720P (~77 GB)..."
huggingface-cli download Wan-AI/Wan2.1-I2V-14B-720P \
  --local-dir "$WEIGHTS/Wan2.1-I2V-14B-720P" || hf download Wan-AI/Wan2.1-I2V-14B-720P \
  --local-dir "$WEIGHTS/Wan2.1-I2V-14B-720P"

echo "[infinitetalk] 2/3 wav2vec2..."
huggingface-cli download TencentGameMate/chinese-wav2vec2-base \
  --local-dir "$WEIGHTS/chinese-wav2vec2-base" 2>/dev/null || \
  hf download TencentGameMate/chinese-wav2vec2-base \
  --local-dir "$WEIGHTS/chinese-wav2vec2-base"

huggingface-cli download TencentGameMate/chinese-wav2vec2-base model.safetensors \
  --revision refs/pr/1 --local-dir "$WEIGHTS/chinese-wav2vec2-base" 2>/dev/null || \
  hf download TencentGameMate/chinese-wav2vec2-base model.safetensors \
  --revision refs/pr/1 --local-dir "$WEIGHTS/chinese-wav2vec2-base"

echo "[infinitetalk] 3/3 InfiniteTalk adapter..."
huggingface-cli download MeiGen-AI/InfiniteTalk \
  --include "single/*" --local-dir "$WEIGHTS/InfiniteTalk" 2>/dev/null || \
  hf download MeiGen-AI/InfiniteTalk \
  --include "single/*" --local-dir "$WEIGHTS/InfiniteTalk"

rm -rf ~/.cache/huggingface/hub
touch "$MARKER"

echo "[infinitetalk] All models downloaded. Ready."
echo ""
echo "Generate: cd /opt/infinitetalk && python generate_infinitetalk.py \\"
echo "  --ckpt_dir $WEIGHTS/Wan2.1-I2V-14B-720P \\"
echo "  --wav2vec_dir $WEIGHTS/chinese-wav2vec2-base \\"
echo "  --infinitetalk_dir $WEIGHTS/InfiniteTalk/single/infinitetalk.safetensors \\"
echo "  --input_json <input.json> --size infinitetalk-720 \\"
echo "  --sample_steps 20 --mode streaming --motion_frame 9 --save_file output"
