#!/usr/bin/env bash
# qompasssai/dotfiles/.config/bob/config.jsonc
# Qompass AI Draft Omarchy Hardening PR
# Copyright (C) 2025 Qompass AI, All rights reserved
#####################################################
set -euo pipefail
hardening_pkgs=(
  age
  buildah
  cni-plugins
  container-diff
  containers-common
  cri-o
  crun
  docker-buildx
  docker-credential-ghcr-login-git
  docker-credential-pass
  docker-credential-secretservice
  docker-rootless-extras
  fuse-overlayfs
  krunvm
  libgcrypt
  netavark
  nerdctl
  pam-gnupg
  pinentry
  pinentry-bemenu
  pinentry-dispatch
  pinentry-dmenu-inco
  wayprompt
  rkhunter
  rtkit
  runc
  skopeo
  slirp4netns
  sops
  ssh-audit
  step-ca
  tufw
  ufw-extras
  uidmap
  wayprompt
)
if lspci | grep -qi nvidia; then
  hardening_pkgs+=(nvidia-container-toolkit)
  echo
  export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
  export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
  mkdir -p "$XDG_CONFIG_HOME/nvidia-container-toolkit"
  cat > "$XDG_CONFIG_HOME/nvidia-container-toolkit/config.toml" << 'EOCONTAINER'
accept-nvidia-visible-devices-as-volume-mounts = false
accept-nvidia-visible-devices-envvar-when-unprivileged = true
disable-require = false
supported-driver-capabilities = "compat32,compute,display,graphics,ngx,utility,video"
swarm-resource = "DOCKER_RESOURCE_GPU"

[nvidia-container-cli]
debug = "${XDG_STATE_HOME}/nvidia-container-toolkit.log"
environment = []
ldconfig = "@/sbin/ldconfig"
load-kmods = true
no-cgroups = true
path = "/usr/bin/nvidia-container-cli"

[nvidia-container-runtime]
debug = "${XDG_STATE_HOME}/nvidia-container-runtime.log"
log-level = "info"
mode = "auto"
runtimes = ["docker-runc", "runc", "crun"]

[nvidia-container-runtime.modes]
[nvidia-container-runtime.modes.cdi]
annotation-prefixes = ["cdi.k8s.io/"]
default-kind = "nvidia.com/gpu"
spec-dirs = ["${XDG_CONFIG_HOME}/cdi", "/etc/cdi", "/var/run/cdi"]

[nvidia-container-runtime.modes.csv]
mount-spec-path = "${XDG_CONFIG_HOME}/nvidia-container-toolkit/host-files-for-container.d"

[nvidia-container-runtime-hook]
path = "nvidia-container-runtime-hook"
skip-mode-detection = false

[nvidia-ctk]
path = "nvidia-ctk"
EOCONTAINER
fi
echo
echo '==> Installing hardening packages'
yay -Sy --needed --noconfirm "${hardening_pkgs[@]}"
echo
echo
echo
echo '==> Disabling Rootful Docker daemon and service'
sudo systemctl disable --now docker.service docker.socket || true
echo
echo '==> Setting up Docker rootless daemon/service for '"$USER"'...'
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

dockerd-rootless-setuptool.sh install || true
systemctl --user enable --now docker.service
loginctl enable-linger "$USER" 2> /dev/null || true

echo
echo '==> Writing ~/.config/docker/config.jsonc...'
mkdir -p "$XDG_CONFIG_HOME/docker"
cat > "$XDG_CONFIG_HOME/docker/config.jsonc" << 'EOCONFIG'
{
// Reference: [https://docs.docker.com/reference/cli/docker/](https://docs.docker.com/reference/cli/docker/)
  "auths": {
    "ghcr.io": {
      "auth": ""
    },
    "https://index.docker.io/v1/": {
      "auth": ""
    },
    "https://index.docker.io/v1/access-token": {
      "auth": ""
    },
    "https://index.docker.io/v1/refresh-token": {
      "auth": ""
    }
  },
  "credsStore": "secretservice",
  "currentContext": "default",
  "detachKeys": "ctrl-e,e",
  "experimental": "enabled",
  "nodesFormat": "table {{.ID}}\t{{.Hostname}}\t{{.Availability}}",
  "plugins": {
    "compose": {
      "build": "bake"
    }
  },
  "pluginsFormat": "table {{.ID}}\t{{.Name}}\t{{.Enabled}}",
  "stackOrchestrator": "swarm"
}
EOCONFIG

echo
echo '==> Writing Rootless Docker Configs'
cat > "$XDG_CONFIG_HOME/docker/daemon.jsonc" << 'EODAEMON'
{
// References: [https://docs.docker.com/engine/daemon/](https://docs.docker.com/engine/daemon/) | [https://docs.docker.com/reference/cli/dockerd/](https://docs.docker.com/reference/cli/dockerd/)
  "allow-direct-routing": false,
  "authorization-plugins": [],
  "bip": "",
  "bip6": "",
  "bridge": "",
  "builder": {
    "enabled": true,
    "defaultKeepStorage": "10GB",
    "policy": [
      { "keepStorage": "10GB", "filter": ["unused-for=2200h"] },
      { "keepStorage": "50GB", "filter": ["unused-for=3300h"] },
      { "keepStorage": "100GB", "all": true }
    ]
  },
  "cgroup-parent": "",
  "containerd": "",
  "containerd-namespace": "docker",
  "containerd-plugins-namespace": "docker-plugins",
  "data-root": "",
  "debug": true,
  "default-address-pools": [
    {
      "base": "172.30.0.0/16",
      "size": 24
    },
    {
      "base": "172.31.0.0/16",
      "size": 24
    }
  ],
  "default-cgroupns-mode": "private",
  "default-gateway": "",
  "default-gateway-v6": "",
  "default-network-opts": {},
  "default-runtime": "nvidia",
  "default-shm-size": "64M",
  "default-ulimits": {
    "nofile": {
      "Hard": 64000,
      "Name": "nofile",
      "Soft": 64000
    }
  },
  "dns": [],
  "dns-opts": [],
  "dns-search": [],
  "exec-opts": [],
  "exec-root": "",
  "experimental": true,
  "features": {
    "cdi": true,
    "containerd-snapshotter": true
  },
  "fixed-cidr": "",
  "fixed-cidr-v6": "fd00:dead:beef::/48",
  "ipv6": true,
  "group": "",
  "host-gateway-ip": "",
  "runtimes": {
    "nvidia": {
      "args": [],
      "path": "nvidia-container-runtime"
    }
  }
}
EODAEMON

echo
echo '==> Creating Userspace Gnu Privacy Guard (Gnupg) S/MIME, Dirmngr, Agent, and Common  configs'
mkdir -p "$HOME/.gnupg"
chmod 700 "$HOME/.gnupg"
echo
cat > "$HOME/.gnupg/gpg.conf" << 'EOGPGCONF'
allow-old-cipher-algos
allow-weak-digest-algos
allow-weak-key-signatures
armor
auto-key-import
auto-key-locate local,keyserver,wkd,dane
auto-key-retrieve
cert-digest-algo SHA512
charset utf-8
compliance gnupg
#default-key #CHANGEME
default-preference-list SHA512 SHA384 SHA256 AES256 AES192 AES ZLIB BZIP2 ZIP Uncompressed
default-recipient-self
enable-dsa2
export-options export-minimal export-clean
import-options import-clean repair-pks-subkey-bug
include-key-block
keyid-format 0xlong
keyserver hkp://keys.openpgp.org
keyserver hkp://keyserver.ubuntu.com
keyserver-options auto-key-retrieve no-honor-keyserver-url include-revoked import-clean timeout=60
list-options show-policy-urls show-notations show-keyserver-urls show-uid-validity
log-file ~/.gnupg/gpg.log
marginals-needed 3
max-cert-depth 5
min-cert-level 2
no-batch
no-comments
no-emit-version
no-escape-from-lines
no-greeting
no-permission-warning
no-secmem-warning
personal-aead-preferences EAX OCB
personal-cipher-preferences AES256 AES192 AES CAMELLIA256 TWOFISH
personal-compress-preferences ZLIB BZIP2 ZIP Uncompressed
personal-digest-preferences SHA512 SHA384 SHA256
photo-viewer "xdg-open %i"
primary-keyring ~/.gnupg/pubring.kbx
require-cross-certification
s2k-cipher-algo AES256
s2k-digest-algo SHA512
status-fd 2
trust-model tofu+pgp
utf8-strings
verify-options show-uid-validity
with-fingerprint
with-keygrip
EOGPGCONF
chmod 600 "$HOME/.gnupg/gpg.conf"
echo
echo '==> Writing ~/.gnupg/gpg-agent.conf...'
cat > "$HOME/.gnupg/gpg-agent.conf" << 'EOGPGAGENT'
allow-loopback-pinentry
allow-preset-passphrase
debug-level guru
default-cache-ttl 86400
default-cache-ttl-ssh 14400
disable-scdaemon
enable-extended-key-format
enable-ssh-support
extra-socket $HOME/.gnupg/S.gpg-agent.extra
ignore-cache-for-signing
keep-tty
log-file $HOME/.gnupg/gpg-agent.log
max-cache-ttl 604800
no-allow-external-cache
no-allow-mark-trusted
no-grab
pinentry-program /usr/bin/pinentry-tty
s2k-count 65011712
scdaemon-program /dev/null
ssh-fingerprint-digest SHA256
EOGPGAGENT
chmod 600 "$HOME/.gnupg/gpg-agent.conf"
echo
echo '==> Writing ~/.gnupg/gpgsm.conf...'
cat > "$HOME/.gnupg/gpgsm.conf" << 'EOGPGSM'
agent-program /usr/bin/gpg-agent
armor
auto-issuer-key-retrieve
batch
cipher-algo AES256
compatibility-flags allow-ka-to-encr
digest-algo SHA512
default-key [map@qompass.ai](mailto:map@qompass.ai)
dirmngr-program /usr/bin/dirmngr
enable-ocsp
include-certs 1
log-file ~/.gnupg/gpgsm.log
log-time
no-secmem-warning
verbose
EOGPGSM
chmod 600 "$HOME/.gnupg/gpgsm.conf"
echo
cat > "$HOME/.gnupg/common.conf" << 'EOCOMMON'
use-keyboxd
EOCOMMON
chmod 600 "$HOME/.gnupg/common.conf"
echo
cat > "$HOME/.gnupg/dirmngr.conf" << 'EODIRMNGR'
allow-ocsp
connect-timeout 30
debug-level advanced
disable-ldap
homedir ~/.gnupg
log-file ~/.gnupg/dirmngr.log
hkp-cacert /etc/ssl/certs/ca-certificates.crt
keyserver hkps://keys.openpgp.org
keyserver hkps://keyserver.ubuntu.com
no-use-tor
verbose
EODIRMNGR
chmod 600 "$HOME/.gnupg/dirmngr.conf"
echo
echo '==> Running Checks'
gpg --gpgconf-test
gpgconf --check-options gpg
gpgconf --check-options gpg-agent
gpgconf --check-options gpgsm
gpgconf --check-options dirmngr
dirmngr --gpgconf-test
sudo update-ca-trust
sudo systemctl enable rtkit-daemon ufw --now
systemctl --user enable pipewire pipewire-pulse wireplumber --now
sudo rkhunter --update
sudo rkhunter --check
export DOCKER_HOST=unix:///run/user/$(id -u)/docker.sock
docker info
echo 'Validation complete.'
