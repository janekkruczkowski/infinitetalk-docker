FROM vastai/pytorch:cuda-12.1.1-auto

ENV PYTHONUNBUFFERED=1
ENV WEIGHTS_DIR=/workspace/models

RUN apt-get update && apt-get install -y --no-install-recommends \
    git-lfs ffmpeg libsndfile1 bc \
    && rm -rf /var/lib/apt/lists/* \
    && git lfs install

RUN . /venv/main/bin/activate && \
    pip install -U xformers && \
    git clone --depth 1 https://github.com/MeiGen-AI/InfiniteTalk.git /opt/infinitetalk && \
    cd /opt/infinitetalk && \
    pip install "misaki[en]" ninja psutil packaging wheel && \
    pip install -r requirements.txt && \
    pip install librosa soundfile huggingface_hub hf_transfer

# Patches
RUN sed -i 's|from inspect import ArgSpec|# from inspect import ArgSpec|' /opt/infinitetalk/wan/multitalk.py || true
RUN sed -i 's|from_pretrained(wav2vec, local_files_only=True)|from_pretrained(wav2vec, local_files_only=True, attn_implementation="eager")|' /opt/infinitetalk/generate_infinitetalk.py || true
COPY patch_attention.py /tmp/patch_attention.py
RUN . /venv/main/bin/activate && python /tmp/patch_attention.py && rm /tmp/patch_attention.py

# Auto-download script (Vast runs via PROVISIONING_SCRIPT env var)
COPY start_infinitetalk.sh /opt/infinitetalk/start_infinitetalk.sh

WORKDIR /opt/infinitetalk
# NO ENTRYPOINT — Vast's native entrypoint handles SSH/supervisor/portal
