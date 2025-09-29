#!/bin/bash

set -ouex pipefail

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/39/x86_64/repoview/index.html&protocol=https&redirect=1

# this installs a package from fedora repos
dnf5 install -y tmux 

# Use a COPR Example:
#
# dnf5 -y copr enable ublue-os/staging
# dnf5 -y install package
# Disable COPRs so they don't end up enabled on the final image:
# dnf5 -y copr disable ublue-os/staging

#### Example for enabling a System Unit File

# Copy the system's podman-restart service to the user location
mkdir -p /var/home/core/.config/systemd/user
cp /lib/systemd/system/podman-restart.service /var/home/core/.config/systemd/user

# Enable the user service
systemctl enable podman.socket
systemctl enable netavark-firewalld-reload.service
systemctl --user enable podman-restart.service

# Check that it's running
systemctl --user list-unit-files | grep podman

