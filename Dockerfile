FROM vastai/pytorch:cuda-12.1.1-auto

ENV PYTHONUNBUFFERED=1

RUN apt-get update && apt-get install -y --no-install-recommends \
    git-lfs ffmpeg libsndfile1 bc \
    && rm -rf /var/lib/apt/lists/* \
    && git lfs install

# Pin torch 2.4.1+cu121 (InfiniteTalk tested stack)
RUN . /venv/main/bin/activate && \
    pip install torch==2.4.1 torchvision==0.19.1 torchaudio==2.4.1 \
    --index-url https://download.pytorch.org/whl/cu121

# Flash Attention 2.7.4
RUN . /venv/main/bin/activate && \
    pip install flash_attn==2.7.4.post1 --no-build-isolation

# xformers
RUN . /venv/main/bin/activate && \
    pip install -U xformers==0.0.28 --index-url https://download.pytorch.org/whl/cu121

# InfiniteTalk native CLI
RUN . /venv/main/bin/activate && \
    git clone --depth 1 https://github.com/MeiGen-AI/InfiniteTalk.git /opt/infinitetalk && \
    cd /opt/infinitetalk && \
    pip install "misaki[en]" ninja psutil packaging wheel && \
    pip install -r requirements.txt && \
    pip install librosa soundfile huggingface_hub hf_transfer

# Patch wav2vec2 eager attention
RUN sed -i 's|from_pretrained(wav2vec, local_files_only=True)|from_pretrained(wav2vec, local_files_only=True, attn_implementation="eager")|' \
    /opt/infinitetalk/generate_infinitetalk.py 2>/dev/null || true

WORKDIR /opt/infinitetalk
