# Stage 1: Download Python wheels on CPU (no CUDA compile).
# Must match runtime Python version — vastai/pytorch:cuda-12.1.1-auto ships Python 3.12.
FROM python:3.12-slim AS downloader

RUN pip install --no-cache-dir pip-tools
RUN pip download torch==2.4.1 torchvision==0.19.1 torchaudio==2.4.1 \
    --index-url https://download.pytorch.org/whl/cu121 \
    -d /wheels
RUN pip download xformers==0.0.28 \
    --index-url https://download.pytorch.org/whl/cu121 \
    -d /wheels
RUN pip download flash_attn==2.7.4.post1 -d /wheels || true


# Stage 2: Runtime (Vast pytorch base, fast boot on Vast.ai)
FROM vastai/pytorch:cuda-12.1.1-auto

ENV PYTHONUNBUFFERED=1 \
    HF_HUB_ENABLE_HF_TRANSFER=1 \
    HF_HUB_DISABLE_XET=1 \
    WEIGHTS_DIR=/workspace/models

RUN apt-get update && apt-get install -y --no-install-recommends \
    git-lfs ffmpeg libsndfile1 bc curl ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && git lfs install

COPY --from=downloader /wheels /tmp/wheels
RUN . /venv/main/bin/activate && \
    pip install --no-cache-dir /tmp/wheels/*.whl && \
    rm -rf /tmp/wheels

# InfiniteTalk native CLI + requirements
RUN . /venv/main/bin/activate && \
    git clone --depth 1 https://github.com/MeiGen-AI/InfiniteTalk.git /opt/infinitetalk && \
    cd /opt/infinitetalk && \
    pip install --no-cache-dir "misaki[en]" ninja psutil packaging wheel && \
    pip install --no-cache-dir -r requirements.txt && \
    pip install --no-cache-dir librosa soundfile "huggingface_hub>=1.11" hf_transfer

# Pin diffusers + transformers AFTER requirements.txt.
# InfiniteTalk's requirements.txt has no upper bound, pip grabs latest which uses PEP 604
# union syntax (T | None) in custom torch ops — torch 2.4.1 infer_schema crashes on it.
RUN . /venv/main/bin/activate && \
    pip install --no-cache-dir 'diffusers==0.33.0' 'transformers==4.49.0'

# Patch: Python 3.12 removed inspect.ArgSpec
RUN sed -i 's|from inspect import ArgSpec|# from inspect import ArgSpec|' \
    /opt/infinitetalk/wan/multitalk.py 2>/dev/null || true

# Patch: wav2vec2 needs eager attention (transformers SDPA doesn't support output_attentions)
RUN sed -i 's|from_pretrained(wav2vec, local_files_only=True)|from_pretrained(wav2vec, local_files_only=True, attn_implementation="eager")|' \
    /opt/infinitetalk/generate_infinitetalk.py 2>/dev/null || true

# Vast boot: /.launch -> /root/onstart.sh. Supervisord is NOT running on Vast.
COPY onstart.sh /root/onstart.sh
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /root/onstart.sh /entrypoint.sh

WORKDIR /opt/infinitetalk
ENTRYPOINT ["/entrypoint.sh"]
