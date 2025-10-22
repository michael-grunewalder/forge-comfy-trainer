# Lightweight Python 3.10 image, no big CUDA layers
FROM python:3.10-slim

ARG IMAGE_VERSION="v1.0.0"
ENV APP_VERSION=${IMAGE_VERSION} \
    DEBIAN_FRONTEND=noninteractive

WORKDIR /opt

RUN apt-get update && apt-get install -y --no-install-recommends \
    git wget curl ffmpeg libgl1 libglib2.0-0 tini procps && \
    rm -rf /var/lib/apt/lists/*

RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
RUN pip install --no-cache-dir --upgrade pip setuptools wheel jupyterlab

COPY start.sh /opt/start.sh
RUN chmod +x /opt/start.sh

ENTRYPOINT ["/usr/bin/tini", "--"]
RUN echo "🧩 Building SD Dev Image - ${APP_VERSION}"
CMD ["/opt/start.sh"]
