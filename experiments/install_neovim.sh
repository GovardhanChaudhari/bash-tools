#!/bin/bash

# This script installs Neovim on Ubuntu 22.04 using the AppImage method.

echo "Starting Neovim installation..."

# 1. Update package lists
echo "Updating package lists..."
sudo apt update -y

# 2. Install necessary dependencies (e.g., for AppImage to run)
echo "Installing necessary dependencies..."
sudo apt install -y curl fuse libfuse2

# 3. Download the latest Neovim AppImage
# Using the specific URL provided by the user.
echo "Downloading Neovim AppImage from: https://github.com/neovim/neovim/releases/download/v0.11.2/nvim-linux-x86_64.appimage"
NEOVIM_APPIMAGE_URL="https://github.com/neovim/neovim/releases/download/v0.11.2/nvim-linux-x86_64.appimage"
wget -O nvim.appimage "$NEOVIM_APPIMAGE_URL"

if [ ! -f "nvim.appimage" ]; then
    echo "Error: Download failed. nvim.appimage not found. Exiting."
    exit 1
fi

# 4. Make the AppImage executable
echo "Making Neovim AppImage executable..."
chmod u+x nvim.appimage

# 5. Move it to a suitable location in the PATH
# /usr/local/bin is a common location for user-installed binaries
echo "Moving Neovim to /usr/local/bin..."
sudo mv nvim.appimage /usr/local/bin/nvim

# 6. Verify installation
echo "Verifying Neovim installation..."
if command -v nvim &> /dev/null; then
    echo "Neovim installed successfully!"
    nvim --version
else
    echo "Error: Neovim installation failed. 'nvim' command not found."
    exit 1
fi

echo "Installation complete."
echo "You can now run 'nvim' from your terminal."
