# Custom ARC runner image for Labgrid.
# Base is intentionally minimal; overlay packages needed for Tranzzer CI
# (pnpm standalone binary + Playwright Chromium).
#
# Pin BASE_TAG when bumping; rebuild before changing the chart image tag.
ARG BASE_TAG=latest
FROM ghcr.io/actions/actions-runner:${BASE_TAG}

USER root
ENV DEBIAN_FRONTEND=noninteractive

# Ubuntu 24.04 (noble) package names — matches current actions-runner ImageOS.
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    libatomic1 \
    jq \
    # Playwright / Chromium runtime (desktop-webapp CI)
    libasound2t64 \
    libatk-bridge2.0-0t64 \
    libatk1.0-0t64 \
    libatspi2.0-0t64 \
    libcairo2 \
    libcups2t64 \
    libdbus-1-3 \
    libdrm2 \
    libgbm1 \
    libglib2.0-0t64 \
    libgtk-3-0t64 \
    libnspr4 \
    libnss3 \
    libpango-1.0-0 \
    libx11-6 \
    libx11-xcb1 \
    libxcb1 \
    libxcomposite1 \
    libxdamage1 \
    libxext6 \
    libxfixes3 \
    libxkbcommon0 \
    libxrandr2 \
    fonts-liberation \
    fonts-noto-color-emoji \
    xdg-utils \
  && ldconfig \
  && test -e /usr/lib/x86_64-linux-gnu/libatomic.so.1 \
  && rm -rf /var/lib/apt/lists/*

USER runner
