# nightwing

Personal [bootc](https://containers.github.io/bootc/) image based on
[Bazzite](https://bazzite.gg/) (`ghcr.io/ublue-os/bazzite-dx-nvidia:stable`),
built with the [ublue-os/image-template](https://github.com/ublue-os/image-template).

## Changes compared to bazzite-dx-nvidia

- **Added packages:** kitty, fira-code-fonts, netbird (from the NetBird repo), virt-manager, mpv
- **Removed packages:** tailscale (replaced by netbird)
- **Virtualization workarounds:** `swtpm-workaround.service` (SELinux label for swtpm) and
  `libvirt-workaround.service` (relabel `/var/lib/libvirt` and `/var/log/libvirt`), enabled by default

## Layout

| Path | Purpose |
|---|---|
| `Containerfile` | Base image and build steps |
| `build_files/build.sh` | Package installation and unit enablement |
| `system_files/` | Files copied verbatim into `/` of the image |
| `image-template.env` | Image name, org and metadata used by the `Justfile` |
| `Justfile` | Local and CI build recipes (`just --list`) |

## Switching to this image

```bash
sudo bootc switch --enforce-container-sigpolicy ghcr.io/dgmann/nightwing:latest
```

Updates afterwards: `sudo bootc upgrade` (or the regular Bazzite updater).

## Building locally

```bash
just build
podman run --rm -it localhost/nightwing:latest bash
```

## Verifying the signature

```bash
cosign verify --key cosign.pub ghcr.io/dgmann/nightwing:latest
```

CI builds daily, signs images pushed from `main` with the `SIGNING_SECRET`
repository secret, and keeps GitHub Actions up to date via Renovate.
