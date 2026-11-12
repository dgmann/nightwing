# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx
COPY build_files /
COPY system_files /system_files
COPY cosign.pub /cosign.pub

# Minimal OpenTelemetry Collector (otelcol/builder-config.yaml). Only the
# binary goes into the image; Go and the sources stay in this stage.
FROM docker.io/library/golang:1.27-alpine AS otelcol
# renovate: datasource=github-releases depName=open-telemetry/opentelemetry-collector-releases extractVersion=^v(?<version>.+)$
ARG OTELCOL_VERSION=0.165.0
COPY otelcol/builder-config.yaml /src/builder-config.yaml
RUN sed -i "s/\${OTELCOL_VERSION}/${OTELCOL_VERSION}/" /src/builder-config.yaml && \
    CGO_ENABLED=0 go install "go.opentelemetry.io/collector/cmd/builder@v${OTELCOL_VERSION}" && \
    CGO_ENABLED=0 builder --config /src/builder-config.yaml --ldflags="-s -w"

# Base Image
FROM ghcr.io/ublue-os/bazzite-dx-nvidia:stable
## Other possible base images include:
# FROM ghcr.io/ublue-os/bazzite:testing
# FROM ghcr.io/ublue-os/aurora:stable
# FROM ghcr.io/ublue-os/bluefin-nvidia-open:stable
# 
# ... and so on, here are more base images
# Universal Blue Images: https://github.com/orgs/ublue-os/packages
# Fedora base image: quay.io/fedora/fedora-bootc:44
# CentOS base images: quay.io/centos-bootc/centos-bootc:stream10

### [IM]MUTABLE /opt
## Some bootable images, like Fedora, have /opt symlinked to /var/opt, in order to
## make it mutable/writable for users. However, some packages write files to this directory,
## thus its contents might be wiped out when bootc deploys an image, making it troublesome for
## some packages. Eg, google-chrome, docker-desktop.
##
## Uncomment the following line if one desires to make /opt immutable and be able to be used
## by the package manager.

# RUN rm /opt && mkdir /opt

### MODIFICATIONS
## make modifications desired in your image and install packages by modifying the build.sh script
## the following RUN directive does all the things required to run "build.sh" as recommended.

COPY --from=otelcol /out/otelcol-host /usr/bin/otelcol-host

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build.sh

### LINTING
## Verify final image and contents are correct. Warnings fail the build.
## nonempty-boot is skipped: /boot/extlinux comes from syslinux-extlinux-nonlinux in the
## base image, which guestfs-tools depends on; bootc does not deploy /boot from the image.
RUN bootc container lint --fatal-warnings --skip nonempty-boot
