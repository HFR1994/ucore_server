#!/bin/bash
# detect-root.sh
# Dynamically detect the root LV or block device at boot.
# This prevents emergency mode when the UUID or LV name changes.

set -euo pipefail

echo "[detect-root] Starting root device detection..."

# Try to find a logical volume that looks like an OSTree or root partition
ROOT_LV=$(ls /dev/mapper/ 2>/dev/null | grep -E 'ostree-root|root|bluefin-root|fedora-root' | head -n1 || true)

if [ -n "${ROOT_LV:-}" ]; then
    ROOT_DEV="/dev/mapper/$ROOT_LV"
    echo "[detect-root] Found LVM root: $ROOT_DEV"
else
    # Fallback: search for an XFS or ext4 filesystem labeled ostree or root
    ROOT_DEV=$(blkid -L ostree-root 2>/dev/null || blkid -L root 2>/dev/null || true)
    if [ -z "${ROOT_DEV:-}" ]; then
        echo "[detect-root] ⚠️ No root LV or labeled partition found!"
        exit 1
    fi
    echo "[detect-root] Found labeled root partition: $ROOT_DEV"
fi

# Ensure device exists before continuing
if [ ! -b "$ROOT_DEV" ]; then
    echo "[detect-root] ⚠️ Device $ROOT_DEV not found in /dev!"
    exit 1
fi

# Make sure /etc/kernel/cmdline.d exists
mkdir -p /etc/kernel/cmdline.d

# Write the detected root device for GRUB and initramfs to use
echo "root=$ROOT_DEV" > /etc/kernel/cmdline.d/99-root.conf
echo "[detect-root] ✅ Root device set to: $ROOT_DEV"

exit 0
