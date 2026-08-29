#!/bin/bash
set -euo pipefail

# ------------------------ Load Shared Helper Functions ------------------------
# Determine the directory of this script and source the shared utils.sh to gain
# access to helper functions like msg and err.
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=utils.sh
source "${SCRIPT_DIR}/utils.sh"

# ------------------------------- Prerequisites -------------------------------
msg "Checking for required commands (wget, unzip, fc-cache)"
if ! aif wget; then err "wget is required but not found"; exit 1; fi
if ! aif unzip; then err "unzip is required but not found"; exit 1; fi
if ! aif fc-cache; then err "fc-cache is required but not found"; exit 1; fi

FONT_NAME="SourceCodePro"
FONT_DOWNLOAD_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/${FONT_NAME}.zip"
INSTALL_DIR="$HOME/.local/share/fonts/NerdFonts"
TEMP_DIR=$(mktemp -d)

msg "Starting installation of ${FONT_NAME} Nerd Font..."

# 1. Create the installation directory if it doesn't exist
mkdir -p "$INSTALL_DIR"

# 2. Download the font zip file
msg "Downloading font from ${FONT_DOWNLOAD_URL}..."
wget -q --show-progress -O "$TEMP_DIR/${FONT_NAME}.zip" "$FONT_DOWNLOAD_URL"

# 3. Unzip the font file
msg "Unzipping font files to a temporary directory..."
unzip -q "$TEMP_DIR/${FONT_NAME}.zip" -d "$TEMP_DIR/$FONT_NAME"

# 4. Move the font files to the installation directory
msg "Moving font files to ${INSTALL_DIR}..."
find "$TEMP_DIR/$FONT_NAME" -name "*.ttf" -o -name "*.otf" | while read -r font_file; do
    mv "$font_file" "$INSTALL_DIR/"
done

# 5. Update the font cache
msg "Updating font cache..."
fc-cache -fv

# 6. Clean up temporary files
msg "Cleaning up temporary files..."
rm -rf "$TEMP_DIR"

msg "${FONT_NAME} Nerd Font installed successfully!"
msg "You may need to restart your terminal or applications to see the new font."

