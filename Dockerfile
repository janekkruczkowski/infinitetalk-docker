FROM pytorch/pytorch:2.4.1-cuda12.1-cudnn9-devel

ENV PYTHONUNBUFFERED=1
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    git git-lfs ffmpeg libsndfile1 bc openssh-server curl \
    && rm -rf /var/lib/apt/lists/* \
    && git lfs install \
    && mkdir -p /run/sshd

# Flash Attention 2.7.4 (prebuilt wheel for torch 2.4 + cu121)
RUN pip install flash_attn==2.7.4.post1 --no-build-isolation

# xformers
RUN pip install -U xformers==0.0.28 --index-url https://download.pytorch.org/whl/cu121

# InfiniteTalk native CLI
RUN git clone --depth 1 https://github.com/MeiGen-AI/InfiniteTalk.git /opt/infinitetalk \
    && cd /opt/infinitetalk \
    && pip install "misaki[en]" ninja psutil packaging wheel \
    && pip install -r requirements.txt \
    && pip install librosa soundfile huggingface_hub hf_transfer

# Patch wav2vec2 eager attention
RUN sed -i 's|from_pretrained(wav2vec, local_files_only=True)|from_pretrained(wav2vec, local_files_only=True, attn_implementation="eager")|' \
    /opt/infinitetalk/generate_infinitetalk.py 2>/dev/null || true

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /opt/infinitetalk
ENTRYPOINT ["/entrypoint.sh"]
