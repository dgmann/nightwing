#!/bin/bash

set -ouex pipefail

# Copy the contents of system_files/ of the git repo to /
cp -avf "/ctx/system_files"/. /

### Install packages
# The base image sets install_weak_deps=False, so weak dependencies that
# rpm-ostree used to pull in are listed explicitly:
#   yt-dlp  - recommended by mpv (URL playback)
#   ripgrep - recommended by kitty (kitten hyperlinked_grep)
dnf5 install -y \
    kitty \
    ripgrep \
    fira-code-fonts \
    virt-manager \
    mpv \
    yt-dlp

# The netbird repo ships disabled (system_files/etc/yum.repos.d/netbird.repo)
# and is only enabled for this transaction. Its %post runs `netbird service
# install/start`, which needs a running systemd, so scriptlets are skipped and
# the unit is shipped in system_files/usr/lib/systemd/system/netbird.service.
dnf5 install -y --enablerepo=netbird --setopt=tsflags=noscripts netbird
# The only other thing its %post does: the env file may hold NB_TPM_PIN.
chmod 0600 /etc/sysconfig/netbird

### Remove packages
dnf5 remove -y tailscale

### Enforce signature verification for this image
# Without a policy entry, ghcr.io/dgmann/nightwing falls through to the
# catch-all "insecureAcceptAnything" scope of the base policy, so updates
# were never checked against cosign.pub. The registries.d entry
# (system_files/etc/containers/registries.d/nightwing.yaml) makes
# containers/image fetch the cosign signatures attached to the image.
install -Dm0644 /ctx/cosign.pub /etc/pki/containers/nightwing.pub
policy=/etc/containers/policy.json
jq '.transports.docker["ghcr.io/dgmann/nightwing"] = [{
      "type": "sigstoreSigned",
      "keyPath": "/etc/pki/containers/nightwing.pub",
      "signedIdentity": {"type": "matchRepository"}
    }]' "$policy" > "$policy.new"
mv "$policy.new" "$policy"

### Enable system units
systemctl enable swtpm-workaround.service
systemctl enable libvirt-workaround.service
# netbird.service is shipped but intentionally not enabled; enable it on the host if wanted.

### Cleanup
# dnf5 leaves runtime state in /run, which must be empty in the final image, and
# may write countme state to /var/lib/dnf (not present in the base image), which
# bootc lint flags as /var content without tmpfiles.d entries.
rm -rf /run/dnf /var/lib/dnf
