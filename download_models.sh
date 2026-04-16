#!/bin/bash
# Pobiera modele na persistent volume. Uruchom RAZ na taniej maszynie.
# Usage: WEIGHTS_DIR=/models bash download_models.sh

set -eu

WEIGHTS="${WEIGHTS_DIR:-/models}"
export HF_HUB_ENABLE_HF_TRANSFER=1

mkdir -p "$WEIGHTS"

echo "==> Wan 2.1 I2V 14B 720P bf16 (~85 GB)"
huggingface-cli download Wan-AI/Wan2.1-I2V-14B-720P \
  --local-dir "$WEIGHTS/Wan2.1-I2V-14B-720P"

echo "==> Chinese wav2vec2 base (~400 MB)"
huggingface-cli download TencentGameMate/chinese-wav2vec2-base \
  --local-dir "$WEIGHTS/chinese-wav2vec2-base"
huggingface-cli download TencentGameMate/chinese-wav2vec2-base model.safetensors \
  --revision refs/pr/1 \
  --local-dir "$WEIGHTS/chinese-wav2vec2-base"

echo "==> InfiniteTalk single adapter (~9 GB)"
huggingface-cli download MeiGen-AI/InfiniteTalk \
  --include "single/*" \
  --local-dir "$WEIGHTS/InfiniteTalk"

echo "==> Done"
du -sh "$WEIGHTS"/*
