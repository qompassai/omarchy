#!/usr/bin/env bash
set -euo pipefail
systemctl --user enable pipewire pipewire-pulse wireplumber --now
pipewire-audio
PIPEWIRE_CONF_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/pipewire.conf.d"
WIREPLUMBER_CONF_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/wireplumber.conf.d"
MODPROBE_BLACKLIST="/etc/modprobe.d/blacklist.conf"
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
cat > "${PIPEWIRE_CONF_DIR}/20-rnnoise.conf" <<'EOF'
context.modules = [
  { name = libpipewire-module-filter-chain
    args = {
      node.description = "RNNoise Mic"
      node.name        = "rnnoise_mic"
      media.class      = "Audio/Source"

      filter.graph = {
        nodes = [
          {
            type   = "ladspa"
            name   = "rnnoise"
            plugin = "/usr/lib/ladspa/librnnoise_ladspa.so"
            label  = "noise_suppressor_mono"
            control = {
              "VAD Threshold (%)"          = 80.0
              "VAD Grace Period (ms)"      = 200
              "Retroactive VAD Grace (ms)" = 0
            }
          }
        ]
      }
      capture.props = {
        node.name   = "capture.rnnoise_source"
        node.target = "echo_cancel_source"
      }
    }
    flags = [ ifexists ]
  }
]
EOF
sudo tee "$MODPROBE_BLACKLIST" >/dev/null <<'EOF'
blacklist pcspkr
EOF
