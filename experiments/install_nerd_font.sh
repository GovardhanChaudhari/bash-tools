#!/bin/bash

FONT_NAME="SourceCodePro"
FONT_DOWNLOAD_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/${FONT_NAME}.zip"
INSTALL_DIR="$HOME/.local/share/fonts/NerdFonts"
TEMP_DIR=$(mktemp -d)

echo "Starting installation of ${FONT_NAME} Nerd Font..."

# 1. Create the installation directory if it doesn't exist
mkdir -p "$INSTALL_DIR"

# 2. Download the font zip file
echo "Downloading font from ${FONT_DOWNLOAD_URL}..."
wget -q --show-progress -O "$TEMP_DIR/${FONT_NAME}.zip" "$FONT_DOWNLOAD_URL"

if [ $? -ne 0 ]; then
    echo "Error: Failed to download the font file. Please check the URL and your internet connection."
    rm -rf "$TEMP_DIR"
    exit 1
fi

# 3. Unzip the font file
echo "Unzipping font files to a temporary directory..."
unzip -q "$TEMP_DIR/${FONT_NAME}.zip" -d "$TEMP_DIR/$FONT_NAME"

if [ $? -ne 0 ]; then
    echo "Error: Failed to unzip the font file."
    rm -rf "$TEMP_DIR"
    exit 1
fi

# 4. Move the font files to the installation directory
echo "Moving font files to ${INSTALL_DIR}..."
find "$TEMP_DIR/$FONT_NAME" -name "*.ttf" -o -name "*.otf" | while read -r font_file; do
    mv "$font_file" "$INSTALL_DIR/"
done

# 5. Update the font cache
echo "Updating font cache..."
fc-cache -fv

# 6. Clean up temporary files
echo "Cleaning up temporary files..."
rm -rf "$TEMP_DIR"

echo "${FONT_NAME} Nerd Font installed successfully!"
echo "You may need to restart your terminal or applications to see the new font."

