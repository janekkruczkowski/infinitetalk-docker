#!/bin/bash
# Runs on Vast first boot via /.launch -> /root/onstart.sh.
# Downloads ~100 GB of models to $WEIGHTS_DIR (persists across restarts).
# ENV:
#   HF_TOKEN   — optional, faster rate limits
#   WEIGHTS_DIR — default /workspace/models
set -e

WEIGHTS="${WEIGHTS_DIR:-/workspace/models}"
MARKER="$WEIGHTS/.download_complete"

mkdir -p "$WEIGHTS"

if [ -f "$MARKER" ]; then
  echo "[infinitetalk] Models cached at $WEIGHTS — ready."
  exit 0
fi

echo "[infinitetalk] First boot — downloading models..."
echo "[infinitetalk] Target: $WEIGHTS"

. /venv/main/bin/activate 2>/dev/null || true
export HF_HUB_ENABLE_HF_TRANSFER=1
export HF_HUB_DISABLE_XET=1

# 1. Wan 2.1 I2V 14B 720P — full repo, ~77 GB
echo "[infinitetalk] 1/4 Wan 2.1 I2V 14B 720P (~77 GB)..."
hf download Wan-AI/Wan2.1-I2V-14B-720P \
  --local-dir "$WEIGHTS/Wan2.1-I2V-14B-720P"

# 2. Chinese wav2vec2 base, ~400 MB
echo "[infinitetalk] 2/4 chinese-wav2vec2-base..."
hf download TencentGameMate/chinese-wav2vec2-base \
  --local-dir "$WEIGHTS/chinese-wav2vec2-base"
hf download TencentGameMate/chinese-wav2vec2-base model.safetensors \
  --revision refs/pr/1 \
  --local-dir "$WEIGHTS/chinese-wav2vec2-base"

# 3. InfiniteTalk — single/ + FP8 quant_models ONLY.
# Skip multi/ (9 GB, not used), comfyui/ (5 GB, not used), int8 quant (~16 GB).
echo "[infinitetalk] 3/4 InfiniteTalk single adapter + FP8 quant (~36 GB)..."
hf download MeiGen-AI/InfiniteTalk \
  --include "single/*" \
  --include "quant_models/infinitetalk_single_fp8.safetensors" \
  --include "quant_models/infinitetalk_single_fp8.json" \
  --include "quant_models/t5_fp8.safetensors" \
  --include "quant_models/t5_map_fp8.json" \
  --include "quant_models/quant.json" \
  --local-dir "$WEIGHTS/InfiniteTalk"

# 4. Clean HF download cache (contains duplicates from --local-dir symlinks)
echo "[infinitetalk] 4/4 Cleaning caches..."
rm -rf "$WEIGHTS/Wan2.1-I2V-14B-720P/.cache" \
       "$WEIGHTS/chinese-wav2vec2-base/.cache" \
       "$WEIGHTS/InfiniteTalk/.cache" \
       ~/.cache/huggingface 2>/dev/null || true

touch "$MARKER"

echo ""
echo "[infinitetalk] Ready. Disk usage:"
du -sh "$WEIGHTS"/*
echo ""
echo "[infinitetalk] To generate:"
echo "  cd /opt/infinitetalk"
echo "  python generate_infinitetalk.py \\"
echo "    --ckpt_dir $WEIGHTS/Wan2.1-I2V-14B-720P \\"
echo "    --wav2vec_dir $WEIGHTS/chinese-wav2vec2-base \\"
echo "    --infinitetalk_dir $WEIGHTS/InfiniteTalk/single/infinitetalk.safetensors \\"
echo "    --quant fp8 \\"
echo "    --quant_dir $WEIGHTS/InfiniteTalk/quant_models/infinitetalk_single_fp8.safetensors \\"
echo "    --input_json input.json --size infinitetalk-720 \\"
echo "    --sample_steps 20 --mode streaming --motion_frame 9 \\"
echo "    --num_persistent_param_in_dit 0 \\"
echo "    --save_file output"
