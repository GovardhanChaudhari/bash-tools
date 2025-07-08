#!/bin/bash

# This script automates the backup of important user data, dotfiles,
# installed package lists, and key system configuration files on Ubuntu.
# It's designed to be run before a major OS upgrade (e.g., 22.04 to 24.04).

# --- Configuration ---
# Define the timestamp format for backup directories
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
LOG_FILE="backup_log_${TIMESTAMP}.log"

# Directories to exclude from home directory backup (add more if needed)
# These are typically caches, temporary files, or large data that can be re-generated
EXCLUDE_DIRS=(
    ".cache"
    ".gvfs"
    ".thumbnails"
    ".local/share/Trash"
    ".mozilla/firefox/*/Cache"
    ".config/google-chrome/*/Cache"
    ".vscode/extensions" # If you have many VS Code extensions cached
    "VirtualBox VMs"    # If you store VMs in your home dir and want to exclude them
    "snap"              # Snap packages often have large data in home
    "Desktop/zoom"      # Example for specific large folders
    "Downloads"         # You might want to exclude downloads if they are large and not critical
)

# Important system configuration files/directories to backup from /etc
# Add or remove based on your specific customizations
ETC_FILES=(
    "/etc/fstab"
    "/etc/apt/sources.list"
    "/etc/apt/sources.list.d" # Directory for additional repositories
    "/etc/hosts"
    "/etc/network/interfaces"
    "/etc/samba/smb.conf"
    "/etc/ssh/sshd_config"
    "/etc/sudoers"
    "/etc/crontab"
    "/etc/X11/xorg.conf" # If you have custom Xorg configurations
    "/etc/default/grub"  # GRUB bootloader configuration
    "/etc/modprobe.d"    # Kernel module configurations
    # Add other service configs if you run a server (e.g., apache2, nginx, mysql)
    # "/etc/apache2"
    # "/etc/nginx"
)

# --- Functions ---

# Function to display messages
log_message() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $1" | tee -a "${BACKUP_DIR}/${LOG_FILE}"
}

# Function to prompt for sudo password if needed
check_sudo() {
    if ! sudo -n true 2>/dev/null; then
        log_message "Sudo password required for system file backups."
        sudo true # This will prompt for the password
    fi
}

# --- Main Script ---

log_message "Starting Ubuntu PC Backup Script..."

# 1. Get backup destination from user
read -p "Enter the absolute path for your backup destination (e.g., /media/your_external_drive/backup): " BACKUP_BASE_PATH

# Validate backup path
if [ -z "$BACKUP_BASE_PATH" ]; then
    log_message "Error: Backup destination cannot be empty. Exiting."
    exit 1
fi

if [ ! -d "$BACKUP_BASE_PATH" ]; then
    log_message "Backup destination '${BACKUP_BASE_PATH}' does not exist. Attempting to create it..."
    mkdir -p "$BACKUP_BASE_PATH"
    if [ $? -ne 0 ]; then
        log_message "Error: Could not create backup destination. Please check permissions or path. Exiting."
        exit 1
    fi
fi

# Create a unique timestamped backup directory within the base path
BACKUP_DIR="${BACKUP_BASE_PATH}/ubuntu_backup_${TIMESTAMP}"
mkdir -p "${BACKUP_DIR}/home_backup"
mkdir -p "${BACKUP_DIR}/package_list"
mkdir -p "${BACKUP_DIR}/etc_configs"

if [ $? -ne 0 ]; then
    log_message "Error: Failed to create backup subdirectories. Exiting."
    exit 1
fi

log_message "Backup will be saved to: ${BACKUP_DIR}"
log_message "Log file: ${BACKUP_DIR}/${LOG_FILE}"

# 2. Backup Home Directory
log_message "--- Backing up Home Directory (${HOME}) ---"
RSYNC_EXCLUDES=""
for dir in "${EXCLUDE_DIRS[@]}"; do
    RSYNC_EXCLUDES+="--exclude=${dir} "
done

# Use rsync for efficient and robust backup of the home directory
# -a: archive mode (preserves permissions, ownership, timestamps, recursive)
# -v: verbose
# -h: human-readable numbers
# --progress: show progress during transfer
# --delete-excluded: remove excluded files from destination if they exist
# --exclude: specify directories/files to exclude
rsync -avh --progress ${RSYNC_EXCLUDES} "${HOME}/" "${BACKUP_DIR}/home_backup/" 2>&1 | tee -a "${BACKUP_DIR}/${LOG_FILE}"

if [ $? -eq 0 ]; then
    log_message "Home directory backup completed successfully."
else
    log_message "Warning: Home directory backup encountered errors. Check log for details."
fi

# 3. Backup List of Installed Packages
log_message "--- Backing up List of Installed Packages ---"
dpkg --get-selections > "${BACKUP_DIR}/package_list/installed_packages_${TIMESTAMP}.log" 2>&1 | tee -a "${BACKUP_DIR}/${LOG_FILE}"

if [ $? -eq 0 ]; then
    log_message "Installed package list saved to: ${BACKUP_DIR}/package_list/installed_packages_${TIMESTAMP}.log"
else
    log_message "Warning: Failed to backup installed package list. Check log for details."
fi

# 4. Backup Important System Configuration Files from /etc
log_message "--- Backing up Important System Configuration Files from /etc ---"
check_sudo # Prompt for sudo password if not already authenticated

for file_path in "${ETC_FILES[@]}"; do
    if [ -e "$file_path" ]; then
        # Create parent directories in the backup location if they don't exist
        # e.g., for /etc/apt/sources.list.d, it will create etc_configs/apt/sources.list.d
        TARGET_PATH="${BACKUP_DIR}/etc_configs${file_path}"
        sudo mkdir -p "$(dirname "$TARGET_PATH")"
        if sudo cp -Rp "$file_path" "$TARGET_PATH" 2>&1 | tee -a "${BACKUP_DIR}/${LOG_FILE}"; then
            log_message "Backed up: ${file_path}"
        else
            log_message "Warning: Failed to backup ${file_path}. Check log for details."
        fi
    else
        log_message "Info: ${file_path} does not exist, skipping."
    fi
done

log_message "System configuration files backup completed."

log_message "--- Backup Process Finished ---"
log_message "Your backup is located at: ${BACKUP_DIR}"
log_message "Please verify the contents of the backup directory."
log_message "It is highly recommended to store this backup on an external drive or cloud storage."
