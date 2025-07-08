#!/bin/bash

# IMPORTANT WARNINGS:
# 1. THIS SCRIPT WILL ERASE ALL DATA ON THE SELECTED USB DRIVE.
#    ENSURE YOU SELECT THE CORRECT DRIVE. DOUBLE-CHECK CAREFULLY!
# 2. THIS SCRIPT ASSUMES YOU ARE RUNNING IT ON A LINUX SYSTEM (e.g., your existing RPi, or another Linux PC).
# 3. INTERNET CONNECTION IS REQUIRED TO DOWNLOAD THE RASPBERRY PI OS IMAGE.
# 4. THE SCRIPT USES 'sudo' FOR ALL DISK OPERATIONS.
# 5. IT IS HIGHLY RECOMMENDED TO BACK UP ANY IMPORTANT DATA BEFORE PROCEEDING.

# --- Configuration Variables ---
# Latest Raspberry Pi OS Lite (64-bit) Bookworm image URL
# ALWAYS VERIFY THIS URL ON THE OFFICIAL RASPBERRY PI WEBSITE FOR THE LATEST VERSION!
IMAGE_URL="https://downloads.raspberrypi.org/raspios_lite_arm64/images/raspios_lite_arm64-2024-03-15/2024-03-15-raspios-bookworm-arm64-lite.img.xz"
IMAGE_XZ_FILENAME=$(basename "$IMAGE_URL")
IMAGE_FILENAME="${IMAGE_XZ_FILENAME%.xz}"

# Partition Sizes (adjust as needed, in MiB)
BOOT_SIZE_MIB=1024  # 1GB for /boot
ROOT_SIZE_MIB=8192  # 8GB for / (rootfs)
VAR_TMPFS_SIZE_MIB=256 # 256MB for /var (tmpfs, in RAM)
SWAP_FILE_SIZE_GB=2 # 2GB for swap file

# Temporary Mount Points
NEW_BOOT_MNT="/mnt/new_rpi_boot"
NEW_ROOT_MNT="/mnt/new_rpi_root"
NEW_HOME_MNT="/mnt/new_rpi_home"
IMG_BOOT_MNT="/mnt/img_rpi_boot"
IMG_ROOT_MNT="/mnt/img_rpi_root"

# --- Functions ---

# Function to display error and exit
error_exit() {
    echo "ERROR: $1" >&2
    cleanup_on_exit
    exit 1
}

# Function to clean up temporary mounts and files on exit
cleanup_on_exit() {
    echo "--- Cleaning up temporary mounts and files ---"
    # Unmount new partitions
    for mnt in "$NEW_BOOT_MNT" "$NEW_ROOT_MNT" "$NEW_HOME_MNT"; do
        if mountpoint -q "$mnt"; then
            echo "Unmounting $mnt..."
            sudo umount "$mnt" || echo "Warning: Could not unmount $mnt. Manual unmount may be required."
        fi
        if [ -d "$mnt" ]; then
            sudo rmdir "$mnt" 2>/dev/null || true # Ignore error if not empty
        fi
    done

    # Unmount image partitions
    for mnt in "$IMG_BOOT_MNT" "$IMG_ROOT_MNT"; do
        if mountpoint -q "$mnt"; then
            echo "Unmounting $mnt..."
            sudo umount "$mnt" || echo "Warning: Could not unmount $mnt. Manual unmount may be required."
        fi
        if [ -d "$mnt" ]; then
            sudo rmdir "$mnt" 2>/dev/null || true # Ignore error if not empty
        fi
    done

    # Remove downloaded image
    if [ -f "$IMAGE_XZ_FILENAME" ]; then
        echo "Removing $IMAGE_XZ_FILENAME..."
        rm "$IMAGE_XZ_FILENAME"
    fi
    if [ -f "$IMAGE_FILENAME" ]; then
        echo "Removing $IMAGE_FILENAME..."
        rm "$IMAGE_FILENAME"
    fi
    echo "Cleanup complete."
}

# Trap signals for cleanup on script exit (even on error)
trap cleanup_on_exit EXIT

# --- Main Script ---

echo "--- Raspberry Pi OS Custom USB Installation Script ---"
echo "This script will partition your selected USB drive and install Raspberry Pi OS."
echo "All data on the selected drive will be ERASED!"
echo ""

# 1. Select Target USB Drive
echo "Available disk drives:"
lsblk -o NAME,SIZE,MODEL,VENDOR,TYPE,MOUNTPOINTS | grep -E 'disk|usb'
echo ""

read -p "Enter the device name of your USB drive (e.g., sda, sdb, sdc): " USB_DEVICE_NAME

if [[ -z "$USB_DEVICE_NAME" ]]; then
    error_exit "No device name entered. Exiting."
fi

TARGET_DRIVE="/dev/${USB_DEVICE_NAME}"

if [[ ! -b "$TARGET_DRIVE" ]]; then
    error_exit "$TARGET_DRIVE is not a valid block device. Exiting."
fi

echo "You have selected: $TARGET_DRIVE"
echo "Contents of $TARGET_DRIVE:"
sudo fdisk -l "$TARGET_DRIVE" || true # Show existing partitions, ignore error if none

read -p "Are you absolutely sure you want to proceed and erase all data on $TARGET_DRIVE? (yes/no): " CONFIRMATION
if [[ ! "$CONFIRMATION" =~ ^[Yy][Ee][Ss]$ ]]; then
    error_exit "Confirmation failed. Exiting."
fi

echo "Proceeding with installation on $TARGET_DRIVE..."
sleep 2

# 2. Unmount any existing partitions on the target drive
echo "--- Unmounting existing partitions on $TARGET_DRIVE ---"
for part in $(lsblk -n -o NAME "$TARGET_DRIVE" | grep -E "${USB_DEVICE_NAME}[0-9]+"); do
    if mountpoint -q "/dev/$part"; then
        echo "Unmounting /dev/$part..."
        sudo umount "/dev/$part" || error_exit "Failed to unmount /dev/$part. Please unmount manually and retry."
    fi
done
sudo partprobe "$TARGET_DRIVE" # Update kernel's partition table

# 3. Partition the USB Drive using parted (GPT)
echo "--- Partitioning $TARGET_DRIVE with GPT ---"
# Calculate end sectors for parted
BOOT_END_MIB=$BOOT_SIZE_MIB
ROOT_END_MIB=$((BOOT_END_MIB + ROOT_SIZE_MIB))

# Use 'parted' for GPT partitioning
sudo parted -s "$TARGET_DRIVE" mklabel gpt || error_exit "Failed to create GPT partition table."

# /boot partition (FAT32)
sudo parted -s "$TARGET_DRIVE" mkpart primary fat32 0% "${BOOT_END_MIB}MiB" || error_exit "Failed to create /boot partition."
sudo parted -s "$TARGET_DRIVE" name 1 boot || error_exit "Failed to name /boot partition."
sudo parted -s "$TARGET_DRIVE" set 1 boot on || error_exit "Failed to set boot flag on /boot partition."

# / (root) partition (ext4)
sudo parted -s "$TARGET_DRIVE" mkpart primary ext4 "${BOOT_END_MIB}MiB" "${ROOT_END_MIB}MiB" || error_exit "Failed to create / (root) partition."
sudo parted -s "$TARGET_DRIVE" name 2 rootfs || error_exit "Failed to name / (root) partition."

# /home partition (ext4) - takes all remaining space
sudo parted -s "$TARGET_DRIVE" mkpart primary ext4 "${ROOT_END_MIB}MiB" 100% || error_exit "Failed to create /home partition."
sudo parted -s "$TARGET_DRIVE" name 3 homefs || error_exit "Failed to name /home partition."

echo "Partitioning complete. New partition table:"
sudo fdisk -l "$TARGET_DRIVE"
sudo partprobe "$TARGET_DRIVE" # Ensure kernel recognizes new partitions

sleep 2

# 4. Format the Partitions
echo "--- Formatting partitions ---"
sudo mkfs.vfat -F 32 "${TARGET_DRIVE}1" || error_exit "Failed to format /boot partition."
sudo mkfs.ext4 -F "${TARGET_DRIVE}2" || error_exit "Failed to format / (root) partition."
sudo mkfs.ext4 -F "${TARGET_DRIVE}3" || error_exit "Failed to format /home partition."
echo "Formatting complete."
sleep 2

# 5. Download and Decompress Raspberry Pi OS Image
echo "--- Downloading Raspberry Pi OS image ---"
if [ ! -f "$IMAGE_FILENAME" ]; then
    if [ ! -f "$IMAGE_XZ_FILENAME" ]; then
        wget -O "$IMAGE_XZ_FILENAME" "$IMAGE_URL" || error_exit "Failed to download image."
    fi
    echo "Decompressing image..."
    unxz "$IMAGE_XZ_FILENAME" || error_exit "Failed to decompress image."
else
    echo "Image already downloaded and decompressed."
fi
sleep 2

# 6. Mount Newly Created Partitions on Target Drive
echo "--- Mounting new partitions on $TARGET_DRIVE ---"
sudo mkdir -p "$NEW_BOOT_MNT" "$NEW_ROOT_MNT" "$NEW_HOME_MNT" || error_exit "Failed to create mount points."
sudo mount "${TARGET_DRIVE}1" "$NEW_BOOT_MNT" || error_exit "Failed to mount ${TARGET_DRIVE}1 to $NEW_BOOT_MNT."
sudo mount "${TARGET_DRIVE}2" "$NEW_ROOT_MNT" || error_exit "Failed to mount ${TARGET_DRIVE}2 to $NEW_ROOT_MNT."
sudo mount "${TARGET_DRIVE}3" "$NEW_HOME_MNT" || error_exit "Failed to mount ${TARGET_DRIVE}3 to $NEW_HOME_MNT."
echo "New partitions mounted."
sleep 2

# 7. Get Image Partition Details and Mount Image Partitions
echo "--- Mounting Raspberry Pi OS image partitions ---"
# Get partition info from the downloaded image
IMAGE_PART_INFO=$(sudo fdisk -l "$IMAGE_FILENAME" | grep -E "${IMAGE_FILENAME}[0-9]+")
BOOT_IMG_LINE=$(echo "$IMAGE_PART_INFO" | grep "${IMAGE_FILENAME}1")
ROOT_IMG_LINE=$(echo "$IMAGE_PART_INFO" | grep "${IMAGE_FILENAME}2")

if [ -z "$BOOT_IMG_LINE" ] || [ -z "$ROOT_IMG_LINE" ]; then
    error_exit "Could not parse image partition information. Check image file or fdisk output."
fi

# Extract start sector and num sectors for boot partition from image
BOOT_IMG_START_SECTOR=$(echo "$BOOT_IMG_LINE" | awk '{print $2}')
BOOT_IMG_NUM_SECTORS=$(echo "$BOOT_IMG_LINE" | awk '{print $4}')

# Extract start sector and num sectors for root partition from image
ROOT_IMG_START_SECTOR=$(echo "$ROOT_IMG_LINE" | awk '{print $2}')
ROOT_IMG_NUM_SECTORS=$(echo "$ROOT_IMG_LINE" | awk '{print $4}')

# Calculate offsets and sizelimits in bytes
BOOT_IMG_OFFSET=$((BOOT_IMG_START_SECTOR * 512))
BOOT_IMG_SIZELIMIT=$((BOOT_IMG_NUM_SECTORS * 512))
ROOT_IMG_OFFSET=$((ROOT_IMG_START_SECTOR * 512))
ROOT_IMG_SIZELIMIT=$((ROOT_IMG_NUM_SECTORS * 512))

# Create mount points for image
sudo mkdir -p "$IMG_BOOT_MNT" "$IMG_ROOT_MNT" || error_exit "Failed to create image mount points."

# Mount image boot partition
sudo mount -t vfat -o loop,offset=$BOOT_IMG_OFFSET,sizelimit=$BOOT_IMG_SIZELIMIT "$IMAGE_FILENAME" "$IMG_BOOT_MNT" || error_exit "Failed to mount image boot partition."

# Mount image root partition
sudo mount -t ext4 -o loop,offset=$ROOT_IMG_OFFSET,sizelimit=$ROOT_IMG_SIZELIMIT "$IMAGE_FILENAME" "$IMG_ROOT_MNT" || error_exit "Failed to mount image root partition."

echo "Image partitions mounted."
sleep 2

# 8. Copy Files from Image to New Partitions
echo "--- Copying files from image to new partitions ---"
echo "Copying boot files..."
sudo rsync -ah --progress "$IMG_BOOT_MNT"/ "$NEW_BOOT_MNT"/ || error_exit "Failed to copy boot files."

echo "Copying root filesystem files..."
# Exclude directories that should be empty or are managed by the running system
sudo rsync -ax --progress \
    --exclude=/dev/* \
    --exclude=/proc/* \
    --exclude=/sys/* \
    --exclude=/tmp/* \
    --exclude=/run/* \
    --exclude=/mnt/* \
    --exclude=/media/* \
    --exclude=/var/* \
    "$IMG_ROOT_MNT"/ "$NEW_ROOT_MNT"/ || error_exit "Failed to copy root files."

echo "File copying complete."
sleep 2

# 9. Unmount Image Partitions
echo "--- Unmounting image partitions ---"
sudo umount "$IMG_BOOT_MNT" || error_exit "Failed to unmount $IMG_BOOT_MNT."
sudo umount "$IMG_ROOT_MNT" || error_exit "Failed to unmount $IMG_ROOT_MNT."
sudo rmdir "$IMG_BOOT_MNT" "$IMG_ROOT_MNT" || error_exit "Failed to remove image mount points."
echo "Image partitions unmounted."
sleep 2

# 10. Configure cmdline.txt on the New Drive
echo "--- Configuring cmdline.txt ---"
NEW_ROOT_PARTUUID=$(sudo blkid -s PARTUUID -o value "${TARGET_DRIVE}2")
if [ -z "$NEW_ROOT_PARTUUID" ]; then
    error_exit "Could not get PARTUUID for new root partition."
fi

# Read original cmdline.txt, replace root=, write back.
CMDLINE_TXT_PATH="$NEW_BOOT_MNT/cmdline.txt"
if [ ! -f "$CMDLINE_TXT_PATH" ]; then
    error_exit "$CMDLINE_TXT_PATH not found. Copying might have failed."
fi

# Use sed to replace the root=PARTUUID line
sudo sed -i "s|root=PARTUUID=[0-9a-fA-F-]\{8\}-[0-9a-fA-F]\{2\}|root=PARTUUID=$NEW_ROOT_PARTUUID|" "$CMDLINE_TXT_PATH" || error_exit "Failed to update cmdline.txt."
echo "cmdline.txt updated with new root PARTUUID."
sleep 2

# 11. Configure fstab on the New Drive
echo "--- Configuring fstab ---"
NEW_BOOT_PARTUUID=$(sudo blkid -s PARTUUID -o value "${TARGET_DRIVE}1")
NEW_HOME_PARTUUID=$(sudo blkid -s PARTUUID -o value "${TARGET_DRIVE}3")

if [ -z "$NEW_BOOT_PARTUUID" ] || [ -z "$NEW_HOME_PARTUUID" ]; then
    error_exit "Could not get all PARTUUIDs for new partitions."
fi

FSTAB_CONTENT=$(cat <<EOF
# This is /etc/fstab for the new Raspberry Pi OS installation.
# Please keep this file in sync with the /etc/fstab file of the
# system that mounted this file.
# For more info, see fstab(5).

# /boot partition
PARTUUID=$NEW_BOOT_PARTUUID /boot           vfat    defaults,noatime  0       2

# / (root) partition
PARTUUID=$NEW_ROOT_PARTUUID /               ext4    defaults,noatime  0       1

# /home partition
PARTUUID=$NEW_HOME_PARTUUID /home           ext4    defaults,noatime  0       2

# /var as tmpfs (RAM-based, volatile for power-cut resilience)
tmpfs /var              tmpfs   defaults,noatime,nosuid,size=${VAR_TMPFS_SIZE_MIB}M        0       0

# /tmp as tmpfs (RAM-based, volatile)
tmpfs /tmp              tmpfs   defaults,noatime,nosuid,size=64M         0       0

# Swap file (will be created on /home)
/home/swapfile none swap defaults 0 0
EOF
)

echo "$FSTAB_CONTENT" | sudo tee "$NEW_ROOT_MNT/etc/fstab" > /dev/null || error_exit "Failed to write fstab."
echo "fstab configured."
sleep 2

# 12. Create and Configure Swap File
echo "--- Creating and configuring swap file ---"
# Disable dphys-swapfile service in the new system if it exists (it will try to use /var/swap)
echo "Disabling dphys-swapfile service in the new OS..."
sudo chroot "$NEW_ROOT_MNT" systemctl disable dphys-swapfile || echo "Warning: dphys-swapfile not found or could not be disabled in chroot."

SWAP_FILE_PATH="$NEW_HOME_MNT/swapfile" # Swap file now on /home partition
echo "Creating ${SWAP_FILE_SIZE_GB}GB swap file at $SWAP_FILE_PATH..."
sudo fallocate -l "${SWAP_FILE_SIZE_GB}G" "$SWAP_FILE_PATH" || error_exit "Failed to create swap file."
sudo chmod 600 "$SWAP_FILE_PATH" || error_exit "Failed to set permissions on swap file."
sudo mkswap "$SWAP_FILE_PATH" || error_exit "Failed to format swap file."
echo "Swap file created and formatted."
sleep 2

# 13. Final Cleanup (unmounts handled by trap)
echo "--- Installation complete! ---"
echo ""
echo "NEXT STEPS:"
echo "1. Safely remove your original Raspberry Pi OS USB drive (if applicable)."
echo "2. Insert the newly prepared USB drive ($TARGET_DRIVE) into your Raspberry Pi 4."
echo "3. Power on your Raspberry Pi 4."
echo "4. After booting, you can verify partitions with 'df -h' and swap with 'swapon --show' or 'free -h'."
echo "5. If your Pi 4 doesn't boot, ensure its EEPROM firmware is up to date for USB boot support."
echo "   You can update the EEPROM using the Raspberry Pi Imager's 'Misc Utility Images' option on an SD card."
echo "6. Remember to move any personal data from your old installation to the new /home partition."
echo "   (Connect your old USB drive, mount its partitions, and use rsync to copy data)."
echo ""
echo "Script finished successfully."