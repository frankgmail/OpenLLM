# syntax=docker/dockerfile-upstream:master
# Adapted from: https://github.com/pytorch/pytorch/blob/master/Dockerfile
FROM nvidia/cuda:12.1.0-base-ubuntu22.04 as base-container

# Automatically set by buildx
ARG TARGETPLATFORM

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  build-essential \
  ca-certificates \
  ccache \
  curl \
  libssl-dev ca-certificates make \
  git python3-pip && \
  rm -rf /var/lib/apt/lists/*

RUN mkdir -p /openllm-python
RUN mkdir -p /openllm-core
RUN mkdir -p /openllm-client

# Install required dependencies
COPY openllm-python/src /openllm-python/src
COPY hatch.toml README.md CHANGELOG.md openllm-python/pyproject.toml /openllm-python/

# Install all required dependencies
# We have to install autoawq first to avoid conflict with torch, then reinstall torch with vllm
# below
RUN --mount=type=cache,target=/root/.cache/pip \
  pip3 install -v --no-cache-dir \
  "ray==2.6.0" "vllm==0.2.2" xformers && \
  pip3 install --no-cache-dir -e /openllm-python/

COPY openllm-core/src openllm-core/src
COPY hatch.toml README.md CHANGELOG.md openllm-core/pyproject.toml /openllm-core/
RUN --mount=type=cache,target=/root/.cache/pip pip3 install -v --no-cache-dir -e /openllm-core/

COPY openllm-client/src openllm-client/src
COPY hatch.toml README.md CHANGELOG.md openllm-client/pyproject.toml /openllm-client/
RUN --mount=type=cache,target=/root/.cache/pip pip3 install -v --no-cache-dir -e /openllm-client/

FROM base-container

ENTRYPOINT ["python3", "-m", "openllm"]
