# nightwing

Personal [bootc](https://containers.github.io/bootc/) image based on
[Bazzite](https://bazzite.gg/) (`ghcr.io/ublue-os/bazzite-dx-nvidia:stable`),
built with the [ublue-os/image-template](https://github.com/ublue-os/image-template).

## Changes compared to bazzite-dx-nvidia

- **Added packages:** kitty, ripgrep, fira-code-fonts, netbird (from the NetBird repo), virt-manager, mpv, yt-dlp
- **Removed packages:** tailscale (replaced by netbird)
- **Virtualization workarounds:** `swtpm-workaround.service` (SELinux label for swtpm) and
  `libvirt-workaround.service` (relabel `/var/lib/libvirt` and `/var/log/libvirt`), enabled by default
- **Host telemetry:** `otelcol-host`, a minimal OpenTelemetry Collector (host metrics and
  journald logs over OTLP/HTTP, ~50 MB instead of the ~400 MB contrib build), see below
- **Signature policy:** updates of `ghcr.io/dgmann/nightwing` must be signed with `cosign.pub`

## Host telemetry (otelcol-host)

The image stays generic: `otelcol-host.service` is enabled but only starts when the host
provides `/etc/otelcol-host/config.yaml`. Endpoint and credentials are host configuration.

1. Copy `/usr/share/doc/otelcol-host/config.example.yaml` to `/etc/otelcol-host/config.yaml`
   and set the endpoint.
2. Store the token as a TPM-bound credential and load it with a drop-in, as described in the
   example's header (`systemd-creds encrypt --with-key=tpm2`, `LoadCredentialEncrypted=`).
3. `systemctl restart otelcol-host`

The collector runs as a dynamic user in the `systemd-journal` group and reads journal entries
from its start on. Its components are listed in `otelcol/builder-config.yaml`; the binary is
built by the OpenTelemetry Collector Builder in a separate Containerfile stage
(`OTELCOL_VERSION`, updated by Renovate).

## Layout

| Path | Purpose |
|---|---|
| `Containerfile` | Base image and build steps |
| `build_files/build.sh` | Package installation and unit enablement |
| `system_files/` | Files copied verbatim into `/` of the image |
| `otelcol/builder-config.yaml` | Components of the `otelcol-host` collector |
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

The image enforces this itself: `cosign.pub` is installed as
`/etc/pki/containers/nightwing.pub` and `/etc/containers/policy.json` requires a
valid signature for `ghcr.io/dgmann/nightwing`, so `bootc upgrade` rejects
unsigned or foreign images. Rotating the signing key therefore needs one
transition build that trusts both keys (`keyPaths`), otherwise hosts can no
longer update.

CI builds daily, signs images pushed from `main` with the `SIGNING_SECRET`
repository secret, and keeps GitHub Actions up to date via Renovate.
