#!/bin/bash
# firmware.sh
# Qompass AI - [Add description here]
# Copyright (C) 2025 Qompass AI, All rights reserved
# ----------------------------------------
set -e
echo "==> Detecting system hardware..."
arch=$(uname -m)
echo "Detected architecture: $arch"
gpu_vendor="unknown"
if lspci | grep -qi "nvidia"; then
        gpu_vendor="nvidia"
elif lspci | grep -qi "amd"; then
        gpu_vendor="amd"
elif lspci | grep -qi "intel"; then
        gpu_vendor="intel"
fi
echo "Detected GPU vendor: $gpu_vendor"
cpu_vendor=$(lscpu | grep 'Vendor ID:' | awk '{print $3}')
echo "Detected CPU vendor: $cpu_vendor"
audio_vendor="unknown"
if lspci | grep -qi "cirrus logic"; then
        audio_vendor="cirrus"
elif lspci | grep -qi "realtek"; then
        audio_vendor="realtek"
elif lspci | grep -qi "intel audio"; then
        audio_vendor="intel"
elif lspci | grep -qi "sof"; then
        audio_vendor="sof"
fi
echo "Detected Audio: $audio_vendor"
firmware_pkgs=()

case $arch in
x86_64)
        firmware_pkgs+=(linux-firmware linux-firmware-whence)
        ;;
aarch64)
        firmware_pkgs+=(edk2-aarch64)
        ;;
arm*)
        firmware_pkgs+=(edk2-arm)
        ;;
esac

case $gpu_vendor in
nvidia)
        firmware_pkgs+=(linux-firmware-nvidia)
        ;;
amd)
        firmware_pkgs+=(linux-firmware-amdgpu linux-firmware-radeon)
        ;;
intel)
        firmware_pkgs+=(linux-firmware-intel)
        ;;
esac

case $cpu_vendor in
GenuineIntel)
        firmware_pkgs+=(linux-firmware-intel)
        ;;
AuthenticAMD)
        firmware_pkgs+=(linux-firmware-amdgpu linux-firmware-radeon) # if iGPU on AMD
        ;;
esac

case $audio_vendor in
cirrus)
        firmware_pkgs+=(linux-firmware-cirrus)
        ;;
realtek)
        firmware_pkgs+=(linux-firmware-realtek)
        ;;
intel | sof)
        firmware_pkgs+=(sof-firmware)
        ;;
esac

wifi=("linux-firmware-atheros" "linux-firmware-broadcom" "linux-firmware-mediatek" "linux-firmware-qcom" "linux-firmware-realtek")
for pkg in "${wifi[@]}"; do
        firmware_pkgs+=("$pkg")
done

firmware_pkgs+=(alsa-firmware)

firmware_pkgs=($(printf '%s\n' "${firmware_pkgs[@]}" | sort -u))

echo "==> These firmware packages will be installed: ${firmware_pkgs[*]}"

for pkg in "${firmware_pkgs[@]}"; do
        if pacman -Qs "^${pkg}$" | grep -q 'installed'; then
                echo "[SKIP] $pkg already installed"
        else
                echo "[INSTALL] $pkg"
                sudo pacman -S --noconfirm --needed "$pkg"
        fi
done
echo "==> Done."
