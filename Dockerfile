FROM pytorch/pytorch:2.4.1-cuda12.1-cudnn9-runtime

ENV PYTHONUNBUFFERED=1
ENV WEIGHTS_DIR=/workspace/models
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    git git-lfs ffmpeg libsndfile1 bc openssh-server \
    && rm -rf /var/lib/apt/lists/* \
    && git lfs install \
    && mkdir -p /run/sshd /workspace

# Flash Attention 2.7.4 — prebuilt wheel dla torch 2.4+cu121+py310
RUN pip install flash_attn==2.7.4.post1 --no-build-isolation

# xformers
RUN pip install -U xformers==0.0.28 --index-url https://download.pytorch.org/whl/cu121

# InfiniteTalk + deps
RUN git clone --depth 1 https://github.com/MeiGen-AI/InfiniteTalk.git /opt/infinitetalk && \
    cd /opt/infinitetalk && \
    pip install "misaki[en]" ninja psutil packaging wheel && \
    pip install -r requirements.txt && \
    pip install librosa soundfile huggingface_hub hf_transfer

# Patch 1: ArgSpec (Python 3.11+ but let's be safe)
RUN sed -i 's|from inspect import ArgSpec|# from inspect import ArgSpec|' \
    /opt/infinitetalk/wan/multitalk.py || true

# Patch 2: wav2vec2 eager attention
RUN sed -i 's|from_pretrained(wav2vec, local_files_only=True)|from_pretrained(wav2vec, local_files_only=True, attn_implementation="eager")|' \
    /opt/infinitetalk/generate_infinitetalk.py || true

# Auto-download script
COPY start_infinitetalk.sh /opt/infinitetalk/start_infinitetalk.sh

# Cleanup pip cache to reduce image size
RUN pip cache purge && rm -rf /root/.cache /tmp/*

WORKDIR /opt/infinitetalk
