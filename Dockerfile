# Stage 1: Download wheels na CPU (GHA runner, bez CUDA)
FROM python:3.10-slim AS downloader

RUN pip install pip-tools
RUN pip download torch==2.4.1 torchvision==0.19.1 torchaudio==2.4.1 \
    --index-url https://download.pytorch.org/whl/cu121 \
    -d /wheels
RUN pip download xformers==0.0.28 \
    --index-url https://download.pytorch.org/whl/cu121 \
    -d /wheels
RUN pip download flash_attn==2.7.4.post1 -d /wheels || true

# Stage 2: Install na Vast base z CUDA
FROM vastai/pytorch:cuda-12.1.1-auto

ENV PYTHONUNBUFFERED=1

RUN apt-get update && apt-get install -y --no-install-recommends \
    git-lfs ffmpeg libsndfile1 bc \
    && rm -rf /var/lib/apt/lists/* \
    && git lfs install

# Kopiuj wheele z stage 1
COPY --from=downloader /wheels /tmp/wheels

# Install z localnych wheeli (bez network, bez CUDA compile)
RUN . /venv/main/bin/activate && \
    pip install /tmp/wheels/*.whl && \
    rm -rf /tmp/wheels

# InfiniteTalk native CLI
RUN . /venv/main/bin/activate && \
    git clone --depth 1 https://github.com/MeiGen-AI/InfiniteTalk.git /opt/infinitetalk && \
    cd /opt/infinitetalk && \
    pip install "misaki[en]" ninja psutil packaging wheel && \
    pip install -r requirements.txt && \
    pip install librosa soundfile huggingface_hub hf_transfer

# Patch wav2vec2
RUN sed -i 's|from_pretrained(wav2vec, local_files_only=True)|from_pretrained(wav2vec, local_files_only=True, attn_implementation="eager")|' \
    /opt/infinitetalk/generate_infinitetalk.py 2>/dev/null || true

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /opt/infinitetalk
ENTRYPOINT ["/entrypoint.sh"]
