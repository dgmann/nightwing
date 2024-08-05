#!/bin/bash

set -ouex pipefail

RELEASE="$(rpm -E %fedora)"


### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/39/x86_64/repoview/index.html&protocol=https&redirect=1

curl -Lo /etc/yum.repos.d/docker-ce.repo https://download.docker.com/linux/fedora/docker-ce.repo
tee /etc/yum.repos.d/netbird.repo <<EOF
[netbird]
name=netbird
baseurl=https://pkgs.netbird.io/yum/
enabled=1
gpgcheck=0
gpgkey=https://pkgs.netbird.io/yum/repodata/repomd.xml.key
repo_gpgcheck=1
EOF

tee /etc/yum.repos.d/vscode.repo <<EOF
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF

sed -i 's@enabled=0@enabled=1@g' /etc/yum.repos.d/_copr_kylegospo-bazzite.repo

# this installs a package from fedora repos
rpm-ostree install kitty \
      fish \
      fira-code-fonts \
      kvantum \
      code \
      netbird \
      docker-ce \
      docker-ce-cli \
      containerd.io \
      docker-buildx-plugin \
      docker-compose-plugin \
      sunshine

rpm-ostree override remove tailscale

# Setup gamescope-session
mkdir -p /usr/share/gamescope-session-plus/
curl -Lo /usr/share/gamescope-session-plus/bootstrap_steam.tar.gz https://large-package-sources.nobaraproject.org/bootstrap_steam.tar.gz
rpm-ostree install \
      gamescope-session-plus \
      gamescope-session-steam

sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/docker-ce.repo
sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/netbird.repo
sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/vscode.repo
sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/_copr_kylegospo-bazzite.repo
