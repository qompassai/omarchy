#!/usr/bin/env bash
# This installs hardware video acceleration for Intel GPUs
set -euo pipefail
INTEL_VIDEO_PACKAGES=(
  libva
  libva-utils
  vulkan-intel
  mesa
  linux-firmware-intel
  libvpl
  vpl-gpu-rt
  libvpl-tools
  opencl-mesa
  ocl-icd
  lib32-ocl-icd
  opencl-caps-viewer-wayland
  lib32-opencl-mesa
)
omarchy-pkg-add "${INTEL_VIDEO_PACKAGES[@]}"
# Detect Intel GPU
if INTEL_GPU=$(lspci | grep -iE 'vga|3d|display' | grep -i 'intel'); then
  INTEL_GPU_LOWER=${INTEL_GPU,,}

  if [[ "$INTEL_GPU_LOWER" == *"hd graphics"* || "$INTEL_GPU_LOWER" == *"xe"* || "$INTEL_GPU_LOWER" == *"iris"* ]]; then
    # HD Graphics and newer
    omarchy-pkg-add intel-media-driver
  elif [[ "$INTEL_GPU_LOWER" == *"gma"* ]]; then
    # Older Intel GMA generations
    omarchy-pkg-add libva-intel-driver
  fi
fi
