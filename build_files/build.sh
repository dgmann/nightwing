#!/bin/bash

set -ouex pipefail

# Copy the contents of system_files/ of the git repo to /
cp -avf "/ctx/system_files"/. /

### Install packages
dnf5 install -y \
    kitty \
    fira-code-fonts \
    virt-manager \
    mpv

# The netbird repo ships disabled (system_files/etc/yum.repos.d/netbird.repo)
# and is only enabled for this transaction. Its %post runs `netbird service
# install/start`, which needs a running systemd, so scriptlets are skipped and
# the unit is shipped in system_files/usr/lib/systemd/system/netbird.service.
dnf5 install -y --enablerepo=netbird --setopt=tsflags=noscripts netbird

### Remove packages
dnf5 remove -y tailscale

### Enable system units
systemctl enable swtpm-workaround.service
systemctl enable libvirt-workaround.service
# netbird.service is shipped but intentionally not enabled; enable it on the host if wanted.

### Cleanup
# dnf5 leaves runtime state in /run, which must be empty in the final image.
rm -rf /run/dnf
