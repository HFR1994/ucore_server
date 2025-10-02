#!/usr/bin/env bash
set -euo pipefail

# Usage check
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <IDE_CODE> <BACKEND_CODE>"
    exit 1
fi

IDE="$1"
BACKEND="$2"

# switch this to eap if you require the early access version
export RELEASE_TYPE=release
export JETBRAINS_BIN_DIR=/opt/jetbrains

# if you have an existing install you should consider removing this directory first
mkdir -p /var/opt
mkdir -p /var/roothome
install -d ${JETBRAINS_BIN_DIR}/jetbrains-clients-downloader

# Download JetBrains clients downloader if not present
if [ ! -x "${JETBRAINS_BIN_DIR}/jetbrains-clients-downloader/bin/jetbrains-clients-downloader" ]; then
    curl -sL "$(curl -s "https://data.services.jetbrains.com/products?code=JCD&release.type=$RELEASE_TYPE&fields=distributions,link,name,releases" \
               | jq -r '.[0].releases[0].downloads.["linux_x86-64"].link')" \
         | tar xzvf - \
           --directory="${JETBRAINS_BIN_DIR}/jetbrains-clients-downloader" \
           --strip-components=1
fi

# Get latest build number
BUILD_NUM=$(curl -s "https://data.services.jetbrains.com/products/releases?code=${IDE}&latest=true&type=${RELEASE_TYPE}" \
            | jq -r ".${IDE}[0].build")

# Download backend
"${JETBRAINS_BIN_DIR}/jetbrains-clients-downloader/bin/jetbrains-clients-downloader" \
    --products-filter "$BACKEND" \
    --platforms-filter linux-x64 \
    --build-filter "$BUILD_NUM" \
    --download-backends "$JETBRAINS_BIN_DIR"

# Extract tar.gz
tar -xvzf "${JETBRAINS_BIN_DIR}/backends/${BACKEND}"/*.tar.gz \
    -C "${JETBRAINS_BIN_DIR}/backends/${BACKEND}"

# Remove tar.gz
rm -rf "${JETBRAINS_BIN_DIR}/backends/${BACKEND}"/*.tar.gz

mv "${JETBRAINS_BIN_DIR}/backends/products.json" "${JETBRAINS_BIN_DIR}/backends/${IDE}.json"

echo "✅ Installed $IDE ($BACKEND)"