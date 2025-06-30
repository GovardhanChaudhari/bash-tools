#!/bin/bash

# Enable strict mode for safer scripting
set -euo pipefail

# ------------------------ Load Shared Helper Functions ------------------------
# Determine the directory of this script and source the shared utils.sh to gain
# access to helper functions like msg and err.
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=utils.sh
source "${SCRIPT_DIR}/utils.sh"

# This script installs Neovim on Ubuntu 22.04 using the AppImage method.

msg "Starting Neovim installation..."

# 1. Update package lists
msg "Updating package lists..."
sudo apt update -y

# 2. Install necessary dependencies (e.g., for AppImage to run)
msg "Installing necessary dependencies..."
sudo apt install -y curl fuse libfuse2

# 3. Download the latest Neovim AppImage
NEOVIM_APPIMAGE_URL="https://github.com/neovim/neovim/releases/download/v0.11.2/nvim-linux-x86_64.appimage"
msg "Downloading Neovim AppImage from: ${NEOVIM_APPIMAGE_URL}"
wget -O nvim.appimage "$NEOVIM_APPIMAGE_URL"

if [ ! -f "nvim.appimage" ]; then
    err "Download failed. nvim.appimage not found. Exiting."
    exit 1
fi

# 4. Make the AppImage executable
msg "Making Neovim AppImage executable..."
chmod u+x nvim.appimage

# 5. Move it to a suitable location in the PATH
# /usr/local/bin is a common location for user-installed binaries
msg "Moving Neovim to /usr/local/bin..."
sudo mv nvim.appimage /usr/local/bin/nvim

# 6. Verify installation
msg "Verifying Neovim installation..."
if aif nvim; then
    msg "Neovim installed successfully!"
    nvim --version || true
else
    err "Neovim installation failed. 'nvim' command not found."
    exit 1
fi

msg "Installation complete. You can now run 'nvim' from your terminal."
