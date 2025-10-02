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

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <output_file> <json_directory>"
    exit 1
fi

OUTPUT_FILE="products.json"
JSON_DIR="/opt/jetbrains/backends"

# Check if directory exists
if [ ! -d "$JSON_DIR" ]; then
    echo "Error: Directory '$JSON_DIR' does not exist"
    exit 1
fi

# Find all JSON files in directory
JSON_FILES=("$JSON_DIR"/*.json)

# Merge all JSON files using jq
jq -s 'add' "${JSON_FILES[@]}" | jq '.' > "$JSON_DIR/$OUTPUT_FILE"

"${JETBRAINS_BIN_DIR}/backends/*/*/bin/remote-dev-server.sh registerBackendLocationForGateway 2>/dev/null || true;