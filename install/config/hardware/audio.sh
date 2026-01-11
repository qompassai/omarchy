#!/usr/bin/env bash
# /qompassai/arch/omarchy/install/config/hardware/audio.sh
# Qompass AI Omarchy Audio PR
# Copyright (C) 2026 Qompass AI, All rights reserved
# ----------------------------------------
# Reference: https://cateee.net/lkddb/web-lkddb/SND_SOC_DMIC.html
#https://www.kernel.org/doc/html/v5.9/sound/soc/machine.html
set -euo pipefail
AUDIO_PACKAGES=(
  pipewire-audio
)
omarchy-pkg-add "${AUDIO_PACKAGES[@]}"
systemctl --user enable pipewire pipewire-pulse wireplumber --now
pipewire-audio
MODPROBE_BLACKLIST="/etc/modprobe.d/blacklist.conf"
PIPEWIRE_CONF_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/pipewire.conf.d"
WIREPLUMBER_CONF_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/wireplumber.conf.d"
mkdir -p "$PIPEWIRE_CONF_DIR" "$WIREPLUMBER_CONF_DIR"
cat > "${PIPEWIRE_CONF_DIR}/10-echo-cancel.conf" <<'EOF'
context.modules = [
  { name = libpipewire-module-echo-cancel
    args = {
      capture.props = {
        node.name   = "capture.mic"
        node.target = "bluez_input.2C_53_D7_F9_2B_25.0"
      }
      playback.props = {
        node.name   = "echo_playback"
        node.target = "alsa_output.pci-0000_01_00.1.pro-output-3"
      }
      source.props = {
        node.name   = "echo_cancel_source"
        media.class = "Audio/Source"
      }
      sink.props = {
        node.name   = "echo_cancel_sink"
        media.class = "Audio/Sink"
      }
    }
    flags = [ ifexists ]
  }
]
EOF
cat > "${PIPEWIRE_CONF_DIR}/monitor_alsa.conf" <<'EOF'
monitor.alsa.rules = [
  {
    matches = [
      { device.name = "~alsa_card.*" }
    ]
    actions = {
      update-props = {
        api.alsa.use-acp = true
        api.alsa.use-ucm = false
      }
    }
  }
  {
    matches = [
      { node.name = "audiorelay-virtual-mic-sink" }
    ]
    actions = {
      update-props = {
        "priority.driver"  = 2000
        "priority.session" = 2000
        "node.description" = "AudioRelay Virtual Mic"
        "media.role"       = "communication"
      }
    }
  }
]
EOF
sudo tee "$MODPROBE_BLACKLIST" >/dev/null <<'EOF'
blacklist snd_soc_dmic
blacklist snd_acp_legacy_mach
blacklist snd_acp_mac
EOF
