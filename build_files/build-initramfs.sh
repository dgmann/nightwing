#!/bin/bash
# Rebuild the initramfs so the dracut overrides in system_files/ take effect.
# Mirrors ublue-os/bazzite build_files/build-initramfs.sh.

set -ouex pipefail

mapfile -t kernels < <(ls /usr/lib/modules)
if [ "${#kernels[@]}" -ne 1 ]; then
    echo "expected exactly one kernel in /usr/lib/modules, found: ${kernels[*]}" >&2
    exit 1
fi
kver="${kernels[0]}"
initramfs="/usr/lib/modules/${kver}/initramfs.img"

# Keep build metadata out of the initramfs, as Bazzite does.
os_release=/usr/lib/os-release
tmp_os_release=$(mktemp)
cp "$os_release" "$tmp_os_release"
sed -Ei -e '/^((OSTREE_)?(IMAGE_)?VERSION|PRETTY_NAME|BUILD_ID|BOOTLOADER_NAME|IMAGE_ID)=/d' "$os_release"

DRACUT_NO_XATTR=1 /usr/bin/dracut \
    --no-hostonly \
    --kver "$kver" \
    --reproducible \
    --add fido2 \
    -f "$initramfs"

cp "$tmp_os_release" "$os_release"
rm "$tmp_os_release"
chmod 0600 "$initramfs"

# Fail the build if a GPU driver slipped back in. If you put one back on
# purpose (see system_files/usr/lib/dracut/dracut.conf.d/99-nvidia.conf),
# remove it from this regex.
if lsinitrd "$initramfs" | grep -E '/(nvidia|amdgpu|i915|xe|nouveau|radeon)\.ko'; then
    echo "GPU driver found in initramfs" >&2
    exit 1
fi
ls -la "$initramfs"
