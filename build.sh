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
      sunshine \
      mpv \
      libvirt-daemon-config-network libvirt-daemon-kvm qemu-kvm virt-install virt-manager virt-viewer \
      neovim python3-neovim

rpm-ostree override remove tailscale

sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/docker-ce.repo
sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/netbird.repo
sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/vscode.repo

# Virtualization workound services
tee /usr/lib/tmpfiles.d/swtpm-workaround.conf <<EOF
C /usr/local/bin/overrides/swtpm - - - - /usr/bin/swtpm
d /var/lib/swtpm-localca 0750 tss tss - -
EOF

tee /usr/lib/systemd/system/swtpm-workaround.service <<EOF
[Unit]
Description=Workaround swtpm not having the correct label
ConditionFileIsExecutable=/usr/bin/swtpm
After=local-fs.target

[Service]
Type=oneshot
# Copy if it doesn't exist
ExecStartPre=/usr/bin/bash -c "[ -x /usr/local/bin/overrides/swtpm ] || /usr/bin/cp /usr/bin/swtpm /usr/local/bin/overrides/swtpm"
# This is faster than using .mount unit. Also allows for the previous line/cleanup
ExecStartPre=/usr/bin/mount --bind /usr/local/bin/overrides/swtpm /usr/bin/swtpm
# Fix SELinux label
ExecStart=/usr/sbin/restorecon /usr/bin/swtpm
# Clean-up after ourselves
ExecStop=/usr/bin/umount /usr/bin/swtpm
ExecStop=/usr/bin/rm /usr/local/bin/overrides/swtpm
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

tee /usr/lib/tmpfiles.d/libvirt-workaround.conf <<EOF
d /var/log/libvirt 0750 - - - -
EOF

tee /usr/lib/systemd/system/libvirt-workaround.service<<EOF
[Unit]
Description=Workaround to relabel libvirt files and directories
ConditionPathIsDirectory=/var/lib/libvirt/
After=local-fs.target

[Service]
Type=oneshot
ExecStart=-/usr/sbin/restorecon -R /var/log/libvirt/
ExecStart=-/usr/sbin/restorecon -R /var/lib/libvirt/
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
