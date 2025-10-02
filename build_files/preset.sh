#!/bin/bash

set -ouex pipefail

# switch this to eap if you require the early access version
export RELEASE_TYPE=release
export JETBRAINS_BIN_DIR=/opt/jetbrains

# if you have an existing install you should consider removing this directory first
mkdir -p /var/opt
mkdir -p /var/roothome
install -d ${JETBRAINS_BIN_DIR}
