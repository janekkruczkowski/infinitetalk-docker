#!/bin/bash
set -eu

WEIGHTS="${WEIGHTS_DIR:-/models}"
GPU_NUM="${GPU_NUM:-1}"

echo "=== InfiniteTalk Native CLI ==="
echo "GPUs:    $GPU_NUM"
echo "Weights: $WEIGHTS"
nvidia-smi --query-gpu=name,memory.total --format=csv
echo ""

# If called with arguments, run generation directly
if [ "$#" -gt 0 ]; then
    exec "$@"
fi

# Default: interactive shell
echo "Ready. Example:"
echo ""
echo "  # Single GPU:"
echo "  python generate_infinitetalk.py \\"
echo "    --ckpt_dir $WEIGHTS/Wan2.1-I2V-14B-720P \\"
echo "    --wav2vec_dir $WEIGHTS/chinese-wav2vec2-base \\"
echo "    --infinitetalk_dir $WEIGHTS/InfiniteTalk/single/infinitetalk.safetensors \\"
echo "    --input_json input.json --size infinitetalk-720 \\"
echo "    --sample_steps 20 --mode streaming --motion_frame 9 \\"
echo "    --save_file output"
echo ""
echo "  # Multi-GPU (2x):"
echo "  torchrun --nproc_per_node=2 --standalone generate_infinitetalk.py \\"
echo "    --dit_fsdp --t5_fsdp --ulysses_size=2 \\"
echo "    --ckpt_dir $WEIGHTS/Wan2.1-I2V-14B-720P \\"
echo "    --wav2vec_dir $WEIGHTS/chinese-wav2vec2-base \\"
echo "    --infinitetalk_dir $WEIGHTS/InfiniteTalk/single/infinitetalk.safetensors \\"
echo "    --input_json input.json --size infinitetalk-720 \\"
echo "    --sample_steps 20 --mode streaming --motion_frame 9 \\"
echo "    --save_file output"
echo ""

exec /bin/bash
