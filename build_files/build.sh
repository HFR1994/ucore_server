#!/bin/bash

set -ouex pipefail

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/39/x86_64/repoview/index.html&protocol=https&redirect=1

# this installs a package from fedora repos
dnf5 install -y tmux jq cockpit wget curl gzip

# Use a COPR Example:
#
# dnf5 -y copr enable ublue-os/staging
# dnf5 -y install package
# Disable COPRs so they don't end up enabled on the final image:
# dnf5 -y copr disable ublue-os/staging

#### Example for enabling a System Unit File

# Enable the user service
systemctl enable podman.socket
systemctl enable netavark-firewalld-reload.service

# switch this to eap if you require the early access version
export RELEASE_TYPE=release
export JETBRAINS_BIN_DIR=/opt/jetbrains

# if you have an existing install you should consider removing this directory first
mkdir -p /var/opt
mkdir -p /var/roothome
install -d ${JETBRAINS_BIN_DIR}/jetbrains-clients-downloader

curl -sL \
        $(curl -s "https://data.services.jetbrains.com/products?code=JCD&release.type=release&fields=distributions%2Clink%2Cname%2Creleases" \
            | jq -r '.[0].releases[0].downloads.["linux_x86-64"].link') \
        | tar xzvf - \
            --directory="${JETBRAINS_BIN_DIR}/jetbrains-clients-downloader"  \
            --strip-components=1



IDE_LIST=("PCP" "WS" "IIU" "CL")
IDE_BACKEND_LIST=("PY" "WS" "IU" "CL")

for i in "${!IDE_LIST[@]}"; do
    BUILD_NUM=$(curl -s "https://data.services.jetbrains.com/products/releases?code=${IDE_LIST[i]}&latest=true&type=${RELEASE_TYPE}" | jq -r ".${IDE_LIST[i]}[0].build");
    
    "${JETBRAINS_BIN_DIR}/jetbrains-clients-downloader/bin/jetbrains-clients-downloader" --products-filter "${IDE_BACKEND_LIST[i]}" --platforms-filter linux-x64 --build-filter "${BUILD_NUM}" --download-backends "${JETBRAINS_BIN_DIR}";
    tar -xvzf "${JETBRAINS_BIN_DIR}/backends/${IDE_BACKEND_LIST[i]}"/*.tar.gz -C "${JETBRAINS_BIN_DIR}/backends/${IDE_BACKEND_LIST[i]}";
    rm -rf "${JETBRAINS_BIN_DIR}/backends/${IDE_BACKEND_LIST[i]}"/*.tar.gz;
    "${JETBRAINS_BIN_DIR}/backends/${IDE_BACKEND_LIST[i]}"/*/bin/remote-dev-server.sh registerBackendLocationForGateway;
done;