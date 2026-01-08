#!/bin/bash
# Omarchy GPU + Vulkan Full Stack Setup

echo "[Omarchy Setup] Detecting GPU and installing Vulkan stack..."

if [ ! -f /etc/mkinitcpio.conf ]; then
    echo "[Omarchy Setup] /etc/mkinitcpio.conf not found. Creating default configuration..."
    sudo tee /etc/mkinitcpio.conf >/dev/null <<'EOF'
# Default mkinitcpio.conf for Arch Linux
MODULES=()
BINARIES=()
FILES=()
HOOKS=(base udev autodetect modconf block filesystems keyboard fsck)
EOF
fi
COMMON_VULKAN_PACKAGES=(
    goverlay
    lib32-mesa
    lib32-vkd3d
    lib32-vulkan-icd-loader
    lib32-vulkan-mesa-layers
    lib32-vulkan-utility-libraries
    lib32-vulkan-validation-layers
    mangohud
    mesa
    vkbasalt
    vkmark
    vkd3d
    vulkan-icd-loader
    vulkan-mesa-layers
    vulkan-tools
    vulkan-utility-libraries
    vulkan-validation-layers
)
install_and_configure() {
    echo "[Omarchy Setup] Installing packages: $*"
    yay -S --needed --noconfirm "$@"
}
if lspci | grep -i 'VGA' | grep -iq 'amd\|ATI'; then
    echo "[Omarchy Setup] AMD GPU detected."

    AMD_PACKAGES=(
        amdvlk
        lib32-amdvlk
        lib32-vulkan-radeon
        vulkan-radeon
        xf86-video-amdgpu
    )

    install_and_configure \
        $(printf "%s\n" "${COMMON_VULKAN_PACKAGES[@]}" | sort) \
        $(printf "%s\n" "${AMD_PACKAGES[@]}" | sort)

    sudo sed -i -E 's/ amdgpu//g' /etc/mkinitcpio.conf
    sudo sed -i -E "s/^(MODULES=\()/\1amdgpu /" /etc/mkinitcpio.conf
    sudo mkinitcpio -P

    echo "[Omarchy Setup] AMD Vulkan configuration complete."

# --------------------------
# Intel GPU Detection
# --------------------------
elif lspci | grep -i 'VGA' | grep -iq 'intel'; then
    echo "[Omarchy Setup] Intel GPU detected."

    INTEL_PACKAGES=(
        lib32-vulkan-intel
        vulkan-intel
    )

    install_and_configure \
        $(printf "%s\n" "${COMMON_VULKAN_PACKAGES[@]}" | sort) \
        $(printf "%s\n" "${INTEL_PACKAGES[@]}" | sort)

    sudo sed -i -E 's/ i915//g' /etc/mkinitcpio.conf
    sudo sed -i -E "s/^(MODULES=\()/\1i915 /" /etc/mkinitcpio.conf
    sudo mkinitcpio -P

    echo "[Omarchy Setup] Intel Vulkan configuration complete."

else
    echo "[Omarchy Setup] No AMD or Intel GPU detected – installing NVIDIA stack (default)."

    NVIDIA_PACKAGES=(
        lib32-vulkan-nouveau
        vulkan-nouveau
    )

    install_and_configure \
        $(printf "%s\n" "${COMMON_VULKAN_PACKAGES[@]}" | sort) \
        $(printf "%s\n" "${NVIDIA_PACKAGES[@]}" | sort)

    sudo sed -i -E 's/ nvidia_drm//g; s/ nvidia_uvm//g; s/ nvidia_modeset//g; s/ nvidia//g;' /etc/mkinitcpio.conf
    sudo sed -i -E "s/^(MODULES=\()/\1nvidia nvidia_modeset nvidia_uvm nvidia_drm /" /etc/mkinitcpio.conf
    sudo mkinitcpio -P

    echo "[Omarchy Setup] NVIDIA Vulkan configuration complete."
fi

echo "[Omarchy Setup] All done! Please reboot your system for changes to take effect."
