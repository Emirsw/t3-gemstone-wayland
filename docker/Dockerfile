# syntax=docker/dockerfile:1
FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ARG TASK_VERSION=v3.51.1

RUN sed -i 's/^Types: deb$/Types: deb deb-src/' /etc/apt/sources.list.d/ubuntu.sources \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
      build-essential ca-certificates curl git devscripts debhelper dpkg-dev \
      fakeroot quilt patch pkg-config cmake extra-cmake-modules meson ninja-build \
      python3 python3-pil python3-mako python3-yaml python3-ply flex bison \
      binutils file jq xz-utils zstd \
      libdrm-dev libexpat1-dev libwayland-dev wayland-protocols libzstd-dev \
      zlib1g-dev libsensors-dev libudev-dev libelf-dev libglvnd-dev \
 && curl -fsSL \
      "https://github.com/go-task/task/releases/download/${TASK_VERSION}/task_linux_arm64.tar.gz" \
    | tar -xz -C /usr/local/bin task \
 && rm -rf /var/lib/apt/lists/*

ENV DEBFULLNAME="T3 Gemstone Build"
ENV DEBEMAIL="wayland@t3gemstone.org"
WORKDIR /repo
CMD ["task", "--list"]

