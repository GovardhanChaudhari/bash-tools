# IMPORTANT WARNINGS:
# 1. THIS MAKEFILE WILL ERASE ALL DATA ON THE SELECTED USB DRIVE.
#    ENSURE YOU SELECT THE CORRECT DRIVE. DOUBLE-CHECK CAREFULLY!
# 2. THIS MAKEFILE ASSUMES YOU ARE RUNNING IT ON A LINUX SYSTEM (e.g., your existing RPi, or another Linux PC).
# 3. INTERNET CONNECTION IS REQUIRED TO DOWNLOAD THE RASPBERRY PI OS IMAGE.
# 4. THE SCRIPT USES 'sudo' FOR ALL DISK OPERATIONS.
# 5. IT IS HIGHLY RECOMMENDED TO BACK UP ANY IMPORTANT DATA BEFORE PROCEEDING.
# 6. MAKE SURE 'parted', 'mkfs.vfat', 'mkfs.ext4', 'wget', 'unxz', 'rsync', 'blkid', 'fallocate', 'mkswap', 'chroot' are installed.

# --- Configuration Variables ---
# Latest Raspberry Pi OS Lite (64-bit) Bookworm image URL
# ALWAYS VERIFY THIS URL ON THE OFFICIAL RASPBERRY PI WEBSITE FOR THE LATEST VERSION!
IMAGE_URL := https://downloads.raspberrypi.org/raspios_lite_arm64/images/raspios_lite_arm64-2024-03-15/2024-03-15-raspios-bookworm-arm64-lite.img.xz
IMAGE_XZ_FILENAME := $(notdir $(IMAGE_URL))
IMAGE_FILENAME := $(basename $(IMAGE_XZ_FILENAME))

# Partition Sizes (adjust as needed, in MiB)
BOOT_SIZE_MIB := 1024  # 1GB for /boot
ROOT_SIZE_MIB := 8192  # 8GB for / (rootfs)
VAR_TMPFS_SIZE_MIB := 256 # 256MB for /var (tmpfs, in RAM)
SWAP_FILE_SIZE_GB := 2 # 2GB for swap file

# Temporary Mount Points
NEW_BOOT_MNT := /mnt/new_rpi_boot
NEW_ROOT_MNT := /mnt/new_rpi_root
NEW_HOME_MNT := /mnt/new_rpi_home
IMG_BOOT_MNT := /mnt/img_rpi_boot
IMG_ROOT_MNT := /mnt/img_rpi_root

# --- Phony Targets ---
.PHONY: all setup_drive download_image mount_partitions copy_files configure_os configure_swap cleanup help

# Default target
all: setup_drive download_image mount_partitions copy_files configure_os configure_swap cleanup

help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  all               : Runs all steps from partitioning to cleanup (default)."
	@echo "  setup_drive       : Prompts for USB drive, unmounts, partitions, and formats it."
	@echo "  download_image    : Downloads and decompresses the Raspberry Pi OS image."
	@echo "  mount_partitions  : Mounts the newly created partitions on the target drive and image partitions."
	@echo "  copy_files        : Copies OS files from the image to the new partitions."
	@echo "  configure_os      : Configures cmdline.txt and fstab on the new OS."
	@echo "  configure_swap    : Creates and configures the swap file on the /home partition."
	@echo "  cleanup           : Unmounts all temporary mounts and removes downloaded image files."
	@echo ""
	@echo "Variables you can override (e.g., make setup_drive USB_DEVICE_NAME=sdb):"
	@echo "  USB_DEVICE_NAME   : The device name of your USB drive (e.g., sda, sdb, sdc)."
	@echo "  IMAGE_URL         : URL for the Raspberry Pi OS image."
	@echo "  BOOT_SIZE_MIB     : Size of /boot partition in MiB (default: 1024)."
	@echo "  ROOT_SIZE_MIB     : Size of / (root) partition in MiB (default: 8192)."
	@echo "  VAR_TMPFS_SIZE_MIB: Size of /var tmpfs in MiB (default: 256)."
	@echo "  SWAP_FILE_SIZE_GB : Size of swap file in GB (default: 2)."
	@echo ""
	@echo "IMPORTANT: Always verify USB_DEVICE_NAME before running any target that modifies the disk!"

# --- Targets ---

setup_drive:
	@echo "--- Starting: Setup Drive ---"
	@echo "Available disk drives:"
	@lsblk -o NAME,SIZE,MODEL,VENDOR,TYPE,MOUNTPOINTS | grep -E 'disk|usb'
	@echo ""
	@if [ -z "$(USB_DEVICE_NAME)" ]; then \
		read -p "Enter the device name of your USB drive (e.g., sda, sdb, sdc): " USB_DEVICE_NAME_INPUT; \
		export USB_DEVICE_NAME=$${USB_DEVICE_NAME_INPUT}; \
	fi
	@if [ -z "$(USB_DEVICE_NAME)" ]; then \
		echo "ERROR: No device name entered. Exiting." >&2; \
		exit 1; \
	fi
	@export TARGET_DRIVE="/dev/$(USB_DEVICE_NAME)"
	@if [[ ! -b "$(TARGET_DRIVE)" ]]; then \
		echo "ERROR: $(TARGET_DRIVE) is not a valid block device. Exiting." >&2; \
		exit 1; \
	fi
	@echo "You have selected: $(TARGET_DRIVE)"
	@echo "Contents of $(TARGET_DRIVE):"
	@sudo fdisk -l "$(TARGET_DRIVE)" || true
	@read -p "Are you absolutely sure you want to proceed and erase all data on $(TARGET_DRIVE)? (yes/no): " CONFIRMATION; \
	if [[ ! "$$CONFIRMATION" =~ ^[Yy][Ee][Ss]$$ ]]; then \
		echo "ERROR: Confirmation failed. Exiting." >&2; \
		exit 1; \
	fi
	@echo "Proceeding with installation on $(TARGET_DRIVE)..."
	@sleep 2

	@echo "--- Unmounting existing partitions on $(TARGET_DRIVE) ---"
	@for part in $$(lsblk -n -o NAME "$(TARGET_DRIVE)" | grep -E "$(USB_DEVICE_NAME)[0-9]+"); do \
		if mountpoint -q "/dev/$$part"; then \
			echo "Unmounting /dev/$$part..."; \
			sudo umount "/dev/$$part" || { echo "ERROR: Failed to unmount /dev/$$part. Please unmount manually and retry." >&2; exit 1; }; \
		fi; \
	done
	@sudo partprobe "$(TARGET_DRIVE)"

	@echo "--- Partitioning $(TARGET_DRIVE) with GPT ---"
	@BOOT_END_MIB=$$(($(BOOT_SIZE_MIB)))
	@ROOT_END_MIB=$$(($$(BOOT_END_MIB) + $$(ROOT_SIZE_MIB)))

	@sudo parted -s "$(TARGET_DRIVE)" mklabel gpt || { echo "ERROR: Failed to create GPT partition table." >&2; exit 1; }
	@sudo parted -s "$(TARGET_DRIVE)" mkpart primary fat32 0% "$${BOOT_END_MIB}MiB" || { echo "ERROR: Failed to create /boot partition." >&2; exit 1; }
	@sudo parted -s "$(TARGET_DRIVE)" name 1 boot || { echo "ERROR: Failed to name /boot partition." >&2; exit 1; }
	@sudo parted -s "$(TARGET_DRIVE)" set 1 boot on || { echo "ERROR: Failed to set boot flag on /boot partition." >&2; exit 1; }
	@sudo parted -s "$(TARGET_DRIVE)" mkpart primary ext4 "$${BOOT_END_MIB}MiB" "$${ROOT_END_MIB}MiB" || { echo "ERROR: Failed to create / (root) partition." >&2; exit 1; }
	@sudo parted -s "$(TARGET_DRIVE)" name 2 rootfs || { echo "ERROR: Failed to name / (root) partition." >&2; exit 1; }
	@sudo parted -s "$(TARGET_DRIVE)" mkpart primary ext4 "$${ROOT_END_MIB}MiB" 100% || { echo "ERROR: Failed to create /home partition." >&2; exit 1; }
	@sudo parted -s "$(TARGET_DRIVE)" name 3 homefs || { echo "ERROR: Failed to name /home partition." >&2; exit 1; }

	@echo "Partitioning complete. New partition table:"
	@sudo fdisk -l "$(TARGET_DRIVE)"
	@sudo partprobe "$(TARGET_DRIVE)"
	@sleep 2

	@echo "--- Formatting partitions ---"
	@sudo mkfs.vfat -F 32 "$(TARGET_DRIVE)1" || { echo "ERROR: Failed to format /boot partition." >&2; exit 1; }
	@sudo mkfs.ext4 -F "$(TARGET_DRIVE)2" || { echo "ERROR: Failed to format / (root) partition." >&2; exit 1; }
	@sudo mkfs.ext4 -F "$(TARGET_DRIVE)3" || { echo "ERROR: Failed to format /home partition." >&2; exit 1; }
	@echo "Formatting complete."
	@sleep 2
	@echo "--- Finished: Setup Drive ---"

download_image:
	@echo "--- Starting: Download Image ---"
	@if [ ! -f "$(IMAGE_FILENAME)" ]; then \
		if [ ! -f "$(IMAGE_XZ_FILENAME)" ]; then \
			echo "Downloading $(IMAGE_XZ_FILENAME)..."; \
			wget -O "$(IMAGE_XZ_FILENAME)" "$(IMAGE_URL)" || { echo "ERROR: Failed to download image." >&2; exit 1; }; \
		fi; \
		echo "Decompressing $(IMAGE_XZ_FILENAME)..."; \
		unxz "$(IMAGE_XZ_FILENAME)" || { echo "ERROR: Failed to decompress image." >&2; exit 1; }; \
	else \
		echo "Image $(IMAGE_FILENAME) already downloaded and decompressed."; \
	fi
	@sleep 2
	@echo "--- Finished: Download Image ---"

mount_partitions: setup_drive download_image
	@echo "--- Starting: Mount Partitions ---"
	@echo "--- Mounting new partitions on $(TARGET_DRIVE) ---"
	@sudo mkdir -p "$(NEW_BOOT_MNT)" "$(NEW_ROOT_MNT)" "$(NEW_HOME_MNT)" || { echo "ERROR: Failed to create mount points." >&2; exit 1; }
	@sudo mount "$(TARGET_DRIVE)1" "$(NEW_BOOT_MNT)" || { echo "ERROR: Failed to mount $(TARGET_DRIVE)1 to $(NEW_BOOT_MNT)." >&2; exit 1; }
	@sudo mount "$(TARGET_DRIVE)2" "$(NEW_ROOT_MNT)" || { echo "ERROR: Failed to mount $(TARGET_DRIVE)2 to $(NEW_ROOT_MNT)." >&2; exit 1; }
	@sudo mount "$(TARGET_DRIVE)3" "$(NEW_HOME_MNT)" || { echo "ERROR: Failed to mount $(TARGET_DRIVE)3 to $(NEW_HOME_MNT)." >&2; exit 1; }
	@echo "New partitions mounted."
	@sleep 2

	@echo "--- Mounting Raspberry Pi OS image partitions ---"
	@IMAGE_PART_INFO=$$(sudo fdisk -l "$(IMAGE_FILENAME)" | grep -E "$(IMAGE_FILENAME)[0-9]+")
	@BOOT_IMG_LINE=$$(echo "$${IMAGE_PART_INFO}" | grep "$(IMAGE_FILENAME)1")
	@ROOT_IMG_LINE=$$(echo "$${IMAGE_PART_INFO}" | grep "$(IMAGE_FILENAME)2")

	@if [ -z "$${BOOT_IMG_LINE}" ] || [ -z "$${ROOT_IMG_LINE}" ]; then \
		echo "ERROR: Could not parse image partition information. Check image file or fdisk output." >&2; \
		exit 1; \
	fi

	@BOOT_IMG_START_SECTOR=$$(echo "$${BOOT_IMG_LINE}" | awk '{print $$2}')
	@BOOT_IMG_NUM_SECTORS=$$(echo "$${BOOT_IMG_LINE}" | awk '{print $$4}')
	@ROOT_IMG_START_SECTOR=$$(echo "$${ROOT_IMG_LINE}" | awk '{print $$2}')
	@ROOT_IMG_NUM_SECTORS=$$(echo "$${ROOT_IMG_LINE}" | awk '{print $$4}')

	@BOOT_IMG_OFFSET=$$(($${BOOT_IMG_START_SECTOR} * 512))
	@BOOT_IMG_SIZELIMIT=$$(($${BOOT_IMG_NUM_SECTORS} * 512))
	@ROOT_IMG_OFFSET=$$(($${ROOT_IMG_START_SECTOR} * 512))
	@ROOT_IMG_SIZELIMIT=$$(($${ROOT_IMG_NUM_SECTORS} * 512))

	@sudo mkdir -p "$(IMG_BOOT_MNT)" "$(IMG_ROOT_MNT)" || { echo "ERROR: Failed to create image mount points." >&2; exit 1; }

	@sudo mount -t vfat -o loop,offset=$${BOOT_IMG_OFFSET},sizelimit=$${BOOT_IMG_SIZELIMIT} "$(IMAGE_FILENAME)" "$(IMG_BOOT_MNT)" || { echo "ERROR: Failed to mount image boot partition." >&2; exit 1; }
	@sudo mount -t ext4 -o loop,offset=$${ROOT_IMG_OFFSET},sizelimit=$${ROOT_IMG_SIZELIMIT} "$(IMAGE_FILENAME)" "$(IMG_ROOT_MNT)" || { echo "ERROR: Failed to mount image root partition." >&2; exit 1; }

	@echo "Image partitions mounted."
	@sleep 2
	@echo "--- Finished: Mount Partitions ---"

copy_files: mount_partitions
	@echo "--- Starting: Copy Files ---"
	@echo "Copying boot files..."
	@sudo rsync -ah --progress "$(IMG_BOOT_MNT)"/ "$(NEW_BOOT_MNT)"/ || { echo "ERROR: Failed to copy boot files." >&2; exit 1; }

	@echo "Copying root filesystem files..."
	@sudo rsync -ax --progress \
		--exclude=/dev/* \
		--exclude=/proc/* \
		--exclude=/sys/* \
		--exclude=/tmp/* \
		--exclude=/run/* \
		--exclude=/mnt/* \
		--exclude=/media/* \
		--exclude=/var/* \
		"$(IMG_ROOT_MNT)"/ "$(NEW_ROOT_MNT)"/ || { echo "ERROR: Failed to copy root files." >&2; exit 1; }

	@echo "File copying complete."
	@sleep 2
	@echo "--- Finished: Copy Files ---"

configure_os: copy_files
	@echo "--- Starting: Configure OS ---"
	@echo "--- Configuring cmdline.txt ---"
	@NEW_ROOT_PARTUUID=$$(sudo blkid -s PARTUUID -o value "$(TARGET_DRIVE)2")
	@if [ -z "$${NEW_ROOT_PARTUUID}" ]; then \
		echo "ERROR: Could not get PARTUUID for new root partition." >&2; \
		exit 1; \
	fi

	@CMDLINE_TXT_PATH="$(NEW_BOOT_MNT)/cmdline.txt"
	@if [ ! -f "$${CMDLINE_TXT_PATH}" ]; then \
		echo "ERROR: $${CMDLINE_TXT_PATH} not found. Copying might have failed." >&2; \
		exit 1; \
	fi

	@sudo sed -i "s|root=PARTUUID=[0-9a-fA-F-]\{8\}-[0-9a-fA-F]\{2\}|root=PARTUUID=$${NEW_ROOT_PARTUUID}|" "$${CMDLINE_TXT_PATH}" || { echo "ERROR: Failed to update cmdline.txt." >&2; exit 1; }
	@echo "cmdline.txt updated with new root PARTUUID."
	@sleep 2

	@echo "--- Configuring fstab ---"
	@NEW_BOOT_PARTUUID=$$(sudo blkid -s PARTUUID -o value "$(TARGET_DRIVE)1")
	@NEW_HOME_PARTUUID=$$(sudo blkid -s PARTUUID -o value "$(TARGET_DRIVE)3")

	@if [ -z "$${NEW_BOOT_PARTUUID}" ] || [ -z "$${NEW_HOME_PARTUUID}" ]; then \
		echo "ERROR: Could not get all PARTUUIDs for new partitions." >&2; \
		exit 1; \
	fi

	@FSTAB_CONTENT=$$(cat <<EOF
# This is /etc/fstab for the new Raspberry Pi OS installation.
# Please keep this file in sync with the /etc/fstab file of the
# system that mounted this file.
# For more info, see fstab(5).

# /boot partition
PARTUUID=$${NEW_BOOT_PARTUUID} /boot           vfat    defaults,noatime  0       2

# / (root) partition
PARTUUID=$${NEW_ROOT_PARTUUID} /               ext4    defaults,noatime  0       1

# /home partition
PARTUUID=$${NEW_HOME_PARTUUID} /home           ext4    defaults,noatime  0       2

# /var as tmpfs (RAM-based, volatile for power-cut resilience)
tmpfs /var              tmpfs   defaults,noatime,nosuid,size=$$(VAR_TMPFS_SIZE_MIB)M        0       0

# /tmp as tmpfs (RAM-based, volatile)
tmpfs /tmp              tmpfs   defaults,noatime,nosuid,size=64M         0       0

# Swap file (will be created on /home)
/home/swapfile none swap defaults 0 0
EOF
)
	@echo "$${FSTAB_CONTENT}" | sudo tee "$(NEW_ROOT_MNT)/etc/fstab" > /dev/null || { echo "ERROR: Failed to write fstab." >&2; exit 1; }
	@echo "fstab configured."
	@sleep 2
	@echo "--- Finished: Configure OS ---"

configure_swap: configure_os
	@echo "--- Starting: Configure Swap ---"
	@echo "Disabling dphys-swapfile service in the new OS..."
	@sudo chroot "$(NEW_ROOT_MNT)" systemctl disable dphys-swapfile || echo "Warning: dphys-swapfile not found or could not be disabled in chroot."

	@SWAP_FILE_PATH="$(NEW_HOME_MNT)/swapfile"
	@echo "Creating $$(SWAP_FILE_SIZE_GB)GB swap file at $${SWAP_FILE_PATH}..."
	@sudo fallocate -l "$$(SWAP_FILE_SIZE_GB)G" "$${SWAP_FILE_PATH}" || { echo "ERROR: Failed to create swap file." >&2; exit 1; }
	@sudo chmod 600 "$${SWAP_FILE_PATH}" || { echo "ERROR: Failed to set permissions on swap file." >&2; exit 1; }
	@sudo mkswap "$${SWAP_FILE_PATH}" || { echo "ERROR: Failed to format swap file." >&2; exit 1; }
	@echo "Swap file created and formatted."
	@sleep 2
	@echo "--- Finished: Configure Swap ---"

cleanup:
	@echo "--- Starting: Cleanup ---"
	@echo "--- Cleaning up temporary mounts and files ---"
	@for mnt in "$(NEW_BOOT_MNT)" "$(NEW_ROOT_MNT)" "$(NEW_HOME_MNT)"; do \
		if mountpoint -q "$$mnt"; then \
			echo "Unmounting $$mnt..."; \
			sudo umount "$$mnt" || echo "Warning: Could not unmount $$mnt. Manual unmount may be required." >&2; \
		fi; \
		if [ -d "$$mnt" ]; then \
			sudo rmdir "$$mnt" 2>/dev/null || true; \
		fi; \
	done

	@for mnt in "$(IMG_BOOT_MNT)" "$(IMG_ROOT_MNT)"; do \
		if mountpoint -q "$$mnt"; then \
			echo "Unmounting $$mnt..."; \
			sudo umount "$$mnt" || echo "Warning: Could not unmount $$mnt. Manual unmount may be required." >&2; \
		fi; \
		if [ -d "$$mnt" ]; then \
			sudo rmdir "$$mnt" 2>/dev/null || true; \
		fi; \
	done

	@if [ -f "$(IMAGE_XZ_FILENAME)" ]; then \
		echo "Removing $(IMAGE_XZ_FILENAME)..."; \
		rm "$(IMAGE_XZ_FILENAME)"; \
	fi
	@if [ -f "$(IMAGE_FILENAME)" ]; then \
		echo "Removing $(IMAGE_FILENAME)..."; \
		rm "$(IMAGE_FILENAME)"; \
	fi
	@echo "Cleanup complete."
	@echo "--- Finished: Cleanup ---"
	@echo ""
	@echo "Installation complete! Your USB drive is ready."
	@echo "NEXT STEPS:"
	@echo "1. Safely remove your original Raspberry Pi OS USB drive (if applicable)."
	@echo "2. Insert the newly prepared USB drive into your Raspberry Pi 4."
	@echo "3. Power on your Raspberry Pi 4."
	@echo "4. After booting, you can verify partitions with 'df -h' and swap with 'swapon --show' or 'free -h'."
	@echo "5. If your Pi 4 doesn't boot, ensure its EEPROM firmware is up to date for USB boot support."
	@echo "   You can update the EEPROM using the Raspberry Pi Imager's 'Misc Utility Images' option on an SD card."
	@echo "6. Remember to move any personal data from your old installation to the new /home partition."
	@echo "   (Connect your old USB drive, mount its partitions, and use rsync to copy data)."
