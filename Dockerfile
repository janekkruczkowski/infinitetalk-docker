# InfiniteTalk z flash-attn — stack testowany przez społeczność
# torch 2.4.1 + cu121 + flash-attn 2.7.4 (prebuilt wheel)
# Target GPU: A100/H100 (SM 8.0/9.0, cu121 compatible)
# NIE działa na Blackwell (SM 12.0)

FROM vastai/pytorch:cuda-12.1.1-auto

ENV PYTHONUNBUFFERED=1
ENV WEIGHTS_DIR=/workspace/models

RUN apt-get update && apt-get install -y --no-install-recommends \
    git-lfs ffmpeg libsndfile1 bc \
    && rm -rf /var/lib/apt/lists/* \
    && git lfs install

# Pin torch 2.4.1+cu121 — flash-attn 2.7.4 has prebuilt wheel for this combo
RUN . /venv/main/bin/activate && \
    pip install torch==2.4.1 torchvision==0.19.1 torchaudio==2.4.1 \
    --index-url https://download.pytorch.org/whl/cu121

# Flash Attention 2.7.4 — PREBUILT WHEEL, instant install
RUN . /venv/main/bin/activate && \
    pip install flash_attn==2.7.4.post1 --no-build-isolation

# xformers matching torch 2.4+cu121
RUN . /venv/main/bin/activate && \
    pip install -U xformers==0.0.28 --index-url https://download.pytorch.org/whl/cu121

# InfiniteTalk + deps
RUN . /venv/main/bin/activate && \
    git clone --depth 1 https://github.com/MeiGen-AI/InfiniteTalk.git /opt/infinitetalk && \
    cd /opt/infinitetalk && \
    pip install "misaki[en]" ninja psutil packaging wheel && \
    pip install -r requirements.txt && \
    pip install librosa soundfile huggingface_hub hf_transfer

# Patch 1: ArgSpec (Python 3.11+)
RUN sed -i 's|from inspect import ArgSpec|# from inspect import ArgSpec|' \
    /opt/infinitetalk/wan/multitalk.py || true

# Patch 2: wav2vec2 eager attention
RUN sed -i 's|from_pretrained(wav2vec, local_files_only=True)|from_pretrained(wav2vec, local_files_only=True, attn_implementation="eager")|' \
    /opt/infinitetalk/generate_infinitetalk.py || true

# Auto-download models on boot via supervisor
COPY start_infinitetalk.sh /opt/infinitetalk/start_infinitetalk.sh
RUN mkdir -p /etc/supervisor/conf.d /var/log/infinitetalk && \
    echo '[program:infinitetalk-setup]' > /etc/supervisor/conf.d/infinitetalk.conf && \
    echo 'command=/opt/infinitetalk/start_infinitetalk.sh' >> /etc/supervisor/conf.d/infinitetalk.conf && \
    echo 'autostart=true' >> /etc/supervisor/conf.d/infinitetalk.conf && \
    echo 'autorestart=false' >> /etc/supervisor/conf.d/infinitetalk.conf && \
    echo 'startsecs=0' >> /etc/supervisor/conf.d/infinitetalk.conf && \
    echo 'stdout_logfile=/var/log/infinitetalk/setup.log' >> /etc/supervisor/conf.d/infinitetalk.conf && \
    echo 'stderr_logfile=/var/log/infinitetalk/setup.log' >> /etc/supervisor/conf.d/infinitetalk.conf

WORKDIR /opt/infinitetalk
