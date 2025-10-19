#!/bin/bash

set -ouex pipefail

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/39/x86_64/repoview/index.html&protocol=https&redirect=1

# this installs a package from fedora repos
dnf5 install -y tmux jq cockpit wget curl gzip lvm2

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

install -Dm755 /ctx/detect-root.sh /usr/local/bin/detect-root.sh

# ---------------------------
# 3️⃣ Register the helper as a boot-time service
# ---------------------------
cat <<'EOF' > /etc/systemd/system/detect-root.service
[Unit]
Description=Detect root LV at boot
DefaultDependencies=no
Before=local-fs.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/detect-root.sh

[Install]
WantedBy=local-fs.target
EOF

systemctl enable detect-root.service

# ---------------------------
# 4️⃣ Create a marker file for post-deploy dracut update
# ---------------------------
# This way, the host can rebuild initramfs after deployment if needed
echo "#!/bin/bash
if [ -d /lib/modules/\$(uname -r) ]; then
  dracut --force --add-drivers dm-mod /boot/initramfs-\$(uname -r).img \$(uname -r)
fi" > /usr/local/sbin/update-initramfs-if-available
chmod +x /usr/local/sbin/update-initramfs-if-available

# OUTPUT_FILE="products.json"
# JSON_DIR="/opt/jetbrains/backends"

# # Check if directory exists
# if [ ! -d "$JSON_DIR" ]; then
#     echo "Error: Directory '$JSON_DIR' does not exist"
#     exit 1
# fi

# # Find all JSON files in directory
# JSON_FILES=("$JSON_DIR"/*.json)

# # Merge all JSON files using jq
# jq -s 'add' "${JSON_FILES[@]}" | jq '.' > "$JSON_DIR/$OUTPUT_FILE"

# find "$JSON_DIR" -type f -path "*/bin/remote-dev-server.sh" | while read -r SCRIPT_PATH; do
#   BACKEND_DIR=$(dirname "$(dirname "$SCRIPT_PATH")")
#   echo "📂 Found backend: $BACKEND_DIR"
#   echo "🚀 Running: $SCRIPT_PATH"
#   # Register backends (ignore errors if the command fails)
#   "$SCRIPT_PATH" "registerBackendLocationForGateway" 2>/dev/null || true
#   echo "------------------------------------------"
# done