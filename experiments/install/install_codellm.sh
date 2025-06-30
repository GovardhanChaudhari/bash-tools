#!/usr/bin/env bash

# This script installs or updates the latest Linux release of CodeLLM from the
# official GitHub releases page: https://github.com/abacusai/codellm-releases/releases
#
# It automatically detects the system architecture (x86_64/amd64 or arm64) and
# downloads the most recent `.deb` package that matches the architecture.  If a
# suitable package cannot be found, the script aborts with an error message.
#
# Usage:
#   bash install_codellm.sh            # install / update CodeLLM for current user
#
# The script requires:
#   * curl (to query the GitHub API and download the release)
#   * sudo (to install the package via dpkg)
#
# You can run the script multiple times; it will simply reinstall the newest
# available version, effectively acting as an updater.

set -euo pipefail

# ------------------------ Load Shared Helper Functions ------------------------
# Determine the directory of this script and source the shared utils.sh to gain
# access to helper functions like msg, err and aif.
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=utils.sh
source "${SCRIPT_DIR}/utils.sh"

# ------------------------------ Helper Functions -----------------------------

# ------------------------------- Prerequisites -------------------------------
msg "Checking for required commands (curl, sudo)"
if ! aif curl; then err "curl is required but not found"; exit 1; fi
if ! aif sudo; then err "sudo is required but not found"; exit 1; fi

# --------------------------- Detect Architecture -----------------------------
ARCH="$(uname -m)"
case "$ARCH" in
    x86_64|amd64)
        ARCH="amd64" ;;  # unify naming
    aarch64|arm64)
        ARCH="arm64" ;;
    *)
        err "Unsupported architecture: $ARCH"; exit 1 ;;
esac
msg "Detected architecture: $ARCH"

# ----------------------- Fetch Latest Release Metadata -----------------------
msg "Fetching latest CodeLLM release information from GitHub API"
API_URL="https://api.github.com/repos/abacusai/codellm-releases/releases/latest"
RELEASE_JSON="$(curl -sL "$API_URL")"

# Extract the browser_download_url for the matching .deb asset
DOWNLOAD_URL="$(echo "$RELEASE_JSON" | grep -E 'browser_download_url.*\.deb' \
                                        | grep -E "${ARCH}" \
                                        | head -n 1 \
                                        | cut -d '"' -f 4)"

if [[ -z "$DOWNLOAD_URL" ]]; then
    err "Could not find a .deb asset for architecture ${ARCH}."
    exit 1
fi

msg "Found package: $DOWNLOAD_URL"

# ------------------------------ Download & Install ---------------------------
TMP_DIR="$(mktemp -d)"
PACKAGE_PATH="${TMP_DIR}/codellm_${ARCH}.deb"

msg "Downloading CodeLLM package..."
curl -L "$DOWNLOAD_URL" -o "$PACKAGE_PATH"

msg "Installing CodeLLM (may prompt for sudo password)"
# Attempt installation; if dependencies are missing let apt fix them.
sudo dpkg -i "$PACKAGE_PATH" || {
    msg "Resolving dependencies via apt-get -f install"
    sudo apt-get -f install -y
}

# ------------------------------- Completion ----------------------------------
msg "Installation complete!"

# Try to display installed version if available
if aif codellm; then
    msg "Installed version:"
    codellm --version || true
else
    msg "You may need to open a new shell or ensure /usr/bin is on your PATH."
fi

# Clean up	rm -rf "$TMP_DIR"
