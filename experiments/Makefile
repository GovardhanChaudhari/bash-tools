# IMPORTANT WARNINGS:
# 1. THIS MAKEFILE WILL ERASE ALL DATA ON THE SELECTED USB DRIVE.
#    ENSURE YOU SELECT THE CORRECT DRIVE. DOUBLE-CHECK CAREFULLY!
# 2. THIS MAKEFILE ASSUMES YOU ARE RUNNING IT ON A LINUX SYSTEM (e.g., your existing RPi, or another Linux PC).
# 3. INTERNET CONNECTION IS REQUIRED TO DOWNLOAD THE RASPBERRY PI OS IMAGE.
# 4. THE SCRIPT USES 'sudo' FOR ALL DISK OPERATIONS.
# 5. IT IS HIGHLY RECOMMENDED TO BACK UP ANY IMPORTANT DATA BEFORE PROCEEDING.
# 6. MAKE SURE 'parted', 'mkfs.vfat', 'mkfs.ext4', 'wget', 'unxz', 'rsync', 'blkid', 'fallocate', 'mkswap', 'chroot' are installed.
#
# --- Partition Layout Strategy ---
# This Makefile creates a 3-partition layout optimized for USB boot on Raspberry Pi:
# 1. /boot (FAT32): Kernel, firmware, and boot configuration files
# 2. / (ext4): Root filesystem for OS and installed packages
# 3. /home (ext4): User data and swap file - uses remaining drive space
# Special configurations:
# - /var and /tmp are mounted as tmpfs (RAM) for power-cut resilience
# - Swap file is placed on /home partition for flexibility
# - All partitions use PARTUUID for reliable mounting

# --- Configuration Variables ---
# Latest Raspberry Pi OS Lite (64-bit) Bookworm image URL
# ALWAYS VERIFY THIS URL ON THE OFFICIAL RASPBERRY PI WEBSITE FOR THE LATEST VERSION!
IMAGE_URL := https://downloads.raspberrypi.org/raspios_lite_arm64/images/raspios_lite_arm64-2024-03-15/2024-03-15-raspios-bookworm-arm64-lite.img.xz
IMAGE_XZ_FILENAME := $(notdir $(IMAGE_URL))
IMAGE_FILENAME := $(basename $(IMAGE_XZ_FILENAME))

# Partition Sizes (adjust as needed, in MiB)
# -----------------------------------------
# BOOT_SIZE_MIB: 1GB boot partition to comfortably hold kernel, firmware, overlays, and accommodate OS updates.
#                This size allows extra space for future versions or custom kernels without requiring repartitioning.
BOOT_SIZE_MIB := 1024  # 1GB for /boot
# ROOT_SIZE_MIB: 8GB root filesystem partition is selected as a balance between minimal footprint and usability,
#               leaving adequate room for installed packages, system logs, and user programs.
ROOT_SIZE_MIB := 8192  # 8GB for / (rootfs)
# VAR_TMPFS_SIZE_MIB: 256MB tmpfs allocated to /var to store volatile data like logs and caches in RAM,
#                     which improves lifespan of SD card and speeds up write-heavy operations, at cost of data persistence.
VAR_TMPFS_SIZE_MIB := 256 # 256MB for /var (tmpfs, in RAM)
# SWAP_FILE_SIZE_GB: 2GB swap file size chosen to provide additional virtual memory without excessive SD card wear,
#                    useful for memory-intensive workloads or running multiple applications simultaneously.
SWAP_FILE_SIZE_GB := 2 # 2GB for swap file

# Temporary Mount Points
NEW_BOOT_MNT := /mnt/new_rpi_boot
NEW_ROOT_MNT := /mnt/new_rpi_root
NEW_HOME_MNT := /mnt/new_rpi_home
IMG_BOOT_MNT := /mnt/img_rpi_boot
IMG_ROOT_MNT := /mnt/img_rpi_root

# USB Device - can be overridden from command line
# Example: make all USB_DEVICE_NAME=sdb
USB_DEVICE_NAME ?=

# Export USB_DEVICE_NAME so it's available to all shell commands
export USB_DEVICE_NAME

# --- Phony Targets ---
.PHONY: all setup_drive download_image mount_partitions copy_files configure_os configure_swap cleanup help check_requirements list_drives

# Default target
all: check_requirements setup_drive download_image mount_partitions copy_files configure_os configure_swap cleanup

help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  all               : Runs all steps from partitioning to cleanup (default)."
	@echo "  list_drives       : Lists all available drives without making any changes."
	@echo "  setup_drive       : Prompts for USB drive selection, unmounts, partitions, and formats it."
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

check_requirements:
	@echo "--- Checking for required tools ---"
	@command -v parted >/dev/null 2>&1 || { echo "ERROR: parted is not installed. Please install it first." >&2; exit 1; }
	@command -v mkfs.vfat >/dev/null 2>&1 || { echo "ERROR: mkfs.vfat is not installed. Please install dosfstools." >&2; exit 1; }
	@command -v mkfs.ext4 >/dev/null 2>&1 || { echo "ERROR: mkfs.ext4 is not installed. Please install e2fsprogs." >&2; exit 1; }
	@command -v wget >/dev/null 2>&1 || { echo "ERROR: wget is not installed. Please install it first." >&2; exit 1; }
	@command -v unxz >/dev/null 2>&1 || { echo "ERROR: unxz is not installed. Please install xz-utils." >&2; exit 1; }
	@command -v rsync >/dev/null 2>&1 || { echo "ERROR: rsync is not installed. Please install it first." >&2; exit 1; }
	@command -v blkid >/dev/null 2>&1 || { echo "ERROR: blkid is not installed. Please install util-linux." >&2; exit 1; }
	@command -v fallocate >/dev/null 2>&1 || { echo "ERROR: fallocate is not installed. Please install util-linux." >&2; exit 1; }
	@command -v mkswap >/dev/null 2>&1 || { echo "ERROR: mkswap is not installed. Please install util-linux." >&2; exit 1; }
	@command -v chroot >/dev/null 2>&1 || { echo "ERROR: chroot is not installed. Please install coreutils." >&2; exit 1; }
	@echo "All required tools are installed."
	@echo ""

# List available drives without making changes
list_drives:
	@echo "--- Available Disk Drives ---"
	@echo ""
	@DRIVE_LIST=$$(lsblk -d -n -o NAME,SIZE,MODEL,VENDOR,TYPE | grep -E 'disk' | nl -v 0); \
	if [ -z "$${DRIVE_LIST}" ]; then \
		echo "No disk drives found."; \
		exit 0; \
	fi; \
	echo "$${DRIVE_LIST}" | while IFS= read -r line; do \
		NUM=$$(echo "$${line}" | awk '{print $$1}'); \
		NAME=$$(echo "$${line}" | awk '{print $$2}'); \
		SIZE=$$(echo "$${line}" | awk '{print $$3}'); \
		MODEL=$$(echo "$${line}" | awk '{for(i=4;i<=NF-1;i++) printf "%s ", $$i; print ""}' | sed 's/[[:space:]]*$$//'); \
		echo "  [$${NUM}] /dev/$${NAME} - $${SIZE} - $${MODEL}"; \
		echo "       Partitions:"; \
		lsblk -n -o NAME,SIZE,FSTYPE,MOUNTPOINTS "/dev/$${NAME}" 2>/dev/null | grep -v "^$${NAME} " | sed 's/^/         /' || echo "         No partitions"; \
		echo ""; \
	done
	@echo "Note: Use 'make setup_drive' to select and prepare a drive for Raspberry Pi OS installation."

# --- Targets ---

setup_drive:
	@echo "--- Starting: Setup Drive ---"
	@echo "Detecting available drives..."
	@echo ""
	@# Create a numbered list of available drives
	@if [ -z "$(USB_DEVICE_NAME)" ]; then \
		echo "Available disk drives:"; \
		echo ""; \
		DRIVE_LIST=$$(lsblk -d -n -o NAME,SIZE,MODEL,VENDOR,TYPE | grep -E 'disk' | nl -v 0); \
		if [ -z "$${DRIVE_LIST}" ]; then \
			echo "ERROR: No disk drives found." >&2; \
			exit 1; \
		fi; \
		echo "$${DRIVE_LIST}" | while IFS= read -r line; do \
			NUM=$$(echo "$${line}" | awk '{print $$1}'); \
			NAME=$$(echo "$${line}" | awk '{print $$2}'); \
			SIZE=$$(echo "$${line}" | awk '{print $$3}'); \
			MODEL=$$(echo "$${line}" | awk '{for(i=4;i<=NF-1;i++) printf "%s ", $$i; print ""}' | sed 's/[[:space:]]*$$//'); \
			echo "  [$${NUM}] /dev/$${NAME} - $${SIZE} - $${MODEL}"; \
		done; \
		echo ""; \
		echo "  [x] Exit without making changes"; \
		echo ""; \
		read -p "Select drive number (or 'x' to exit): " SELECTION; \
		if [ "$${SELECTION}" = "x" ] || [ "$${SELECTION}" = "X" ]; then \
			echo "Exiting without changes."; \
			exit 0; \
		fi; \
		if ! echo "$${SELECTION}" | grep -qE '^[0-9]+$$'; then \
			echo "ERROR: Invalid selection. Please enter a number." >&2; \
			exit 1; \
		fi; \
		USB_DEVICE_NAME=$$(echo "$${DRIVE_LIST}" | sed -n "$$(($${SELECTION} + 1))p" | awk '{print $$2}'); \
		if [ -z "$${USB_DEVICE_NAME}" ]; then \
			echo "ERROR: Invalid drive number selected." >&2; \
			exit 1; \
		fi; \
	else \
		USB_DEVICE_NAME=$(USB_DEVICE_NAME); \
	fi; \
	TARGET_DRIVE="/dev/$${USB_DEVICE_NAME}"; \
	if [ ! -b "$${TARGET_DRIVE}" ]; then \
		echo "ERROR: $${TARGET_DRIVE} is not a valid block device. Exiting." >&2; \
		exit 1; \
	fi; \
	echo ""; \
	echo "You have selected: $${TARGET_DRIVE}"; \
	echo ""; \
	echo "Details of selected drive:"; \
	lsblk -o NAME,SIZE,TYPE,MOUNTPOINTS,MODEL,VENDOR "$${TARGET_DRIVE}" 2>/dev/null || true; \
	echo ""; \
	echo "Partition layout:"; \
	sudo fdisk -l "$${TARGET_DRIVE}" 2>/dev/null | grep -E "^(/dev/|Disk model:|Disk /dev/)" || true; \
	echo ""; \
	read -p "Are you absolutely sure you want to proceed and ERASE ALL DATA on $${TARGET_DRIVE}? (yes/no): " CONFIRMATION; \
	if [ "$${CONFIRMATION}" != "yes" ] && [ "$${CONFIRMATION}" != "YES" ]; then \
		echo "Operation cancelled. Exiting." >&2; \
		exit 1; \
	fi; \
	echo "Proceeding with installation on $${TARGET_DRIVE}..."; \
	sleep 2; \
	echo "--- Unmounting existing partitions on $${TARGET_DRIVE} ---"; \
	for part in $$(lsblk -n -o NAME "$${TARGET_DRIVE}" | grep -E "$${USB_DEVICE_NAME}[0-9]+"); do \
		if mountpoint -q "/dev/$$part"; then \
			echo "Unmounting /dev/$$part..."; \
			sudo umount "/dev/$$part" || { echo "ERROR: Failed to unmount /dev/$$part. Please unmount manually and retry." >&2; exit 1; }; \
		fi; \
	done; \
	sudo partprobe "$${TARGET_DRIVE}"; \
	echo "--- Partitioning $${TARGET_DRIVE} with GPT ---"; \
	BOOT_END_MIB=$$(($(BOOT_SIZE_MIB))); \
	ROOT_END_MIB=$$(($$BOOT_END_MIB + $(ROOT_SIZE_MIB))); \
	sudo parted -s "$${TARGET_DRIVE}" mklabel gpt || { echo "ERROR: Failed to create GPT partition table." >&2; exit 1; }; \
	sudo parted -s "$${TARGET_DRIVE}" mkpart primary fat32 0% "$${BOOT_END_MIB}MiB" || { echo "ERROR: Failed to create /boot partition." >&2; exit 1; }; \
	sudo parted -s "$${TARGET_DRIVE}" name 1 boot || { echo "ERROR: Failed to name /boot partition." >&2; exit 1; }; \
	sudo parted -s "$${TARGET_DRIVE}" set 1 boot on || { echo "ERROR: Failed to set boot flag on /boot partition." >&2; exit 1; }; \
	sudo parted -s "$${TARGET_DRIVE}" mkpart primary ext4 "$${BOOT_END_MIB}MiB" "$${ROOT_END_MIB}MiB" || { echo "ERROR: Failed to create / (root) partition." >&2; exit 1; }; \
	sudo parted -s "$${TARGET_DRIVE}" name 2 rootfs || { echo "ERROR: Failed to name / (root) partition." >&2; exit 1; }; \
	sudo parted -s "$${TARGET_DRIVE}" mkpart primary ext4 "$${ROOT_END_MIB}MiB" 100% || { echo "ERROR: Failed to create /home partition." >&2; exit 1; }; \
	sudo parted -s "$${TARGET_DRIVE}" name 3 homefs || { echo "ERROR: Failed to name /home partition." >&2; exit 1; }; \
	echo "Partitioning complete. New partition table:"; \
	sudo fdisk -l "$${TARGET_DRIVE}"; \
	sudo partprobe "$${TARGET_DRIVE}"; \
	sleep 2; \
	echo "--- Formatting partitions ---"; \
	sudo mkfs.vfat -F 32 "$${TARGET_DRIVE}1" || { echo "ERROR: Failed to format /boot partition." >&2; exit 1; }; \
	sudo mkfs.ext4 -F "$${TARGET_DRIVE}2" || { echo "ERROR: Failed to format / (root) partition." >&2; exit 1; }; \
	sudo mkfs.ext4 -F "$${TARGET_DRIVE}3" || { echo "ERROR: Failed to format /home partition." >&2; exit 1; }; \
	echo "Formatting complete."; \
	sleep 2
	@echo "--- Finished: Setup Drive ---"

download_image:
	@echo "--- Starting: Download Image ---"
	@# Check available disk space before downloading (need ~2.5GB for compressed + uncompressed)
	@REQUIRED_SPACE_MB=2500; \
	AVAILABLE_SPACE_KB=$$(df . | tail -1 | awk '{print $$4}'); \
	AVAILABLE_SPACE_MB=$$(($$AVAILABLE_SPACE_KB / 1024)); \
	if [ $$AVAILABLE_SPACE_MB -lt $$REQUIRED_SPACE_MB ]; then \
		echo "ERROR: Insufficient disk space. Need at least $${REQUIRED_SPACE_MB}MB, but only $${AVAILABLE_SPACE_MB}MB available." >&2; \
		exit 1; \
	fi
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
	@echo "--- Mounting new partitions ---"
	@# Re-determine TARGET_DRIVE from USB_DEVICE_NAME
	@if [ -z "$(USB_DEVICE_NAME)" ]; then \
		echo "ERROR: USB_DEVICE_NAME not set. Please specify it when running make (e.g., make mount_partitions USB_DEVICE_NAME=sdb)." >&2; \
		exit 1; \
	fi
	@TARGET_DRIVE="/dev/$(USB_DEVICE_NAME)"; \
	sudo mkdir -p "$(NEW_BOOT_MNT)" "$(NEW_ROOT_MNT)" "$(NEW_HOME_MNT)" || { echo "ERROR: Failed to create mount points." >&2; exit 1; }; \
	sudo mount "$${TARGET_DRIVE}1" "$(NEW_BOOT_MNT)" || { echo "ERROR: Failed to mount $${TARGET_DRIVE}1 to $(NEW_BOOT_MNT)." >&2; exit 1; }; \
	sudo mount "$${TARGET_DRIVE}2" "$(NEW_ROOT_MNT)" || { echo "ERROR: Failed to mount $${TARGET_DRIVE}2 to $(NEW_ROOT_MNT)." >&2; exit 1; }; \
	sudo mount "$${TARGET_DRIVE}3" "$(NEW_HOME_MNT)" || { echo "ERROR: Failed to mount $${TARGET_DRIVE}3 to $(NEW_HOME_MNT)." >&2; exit 1; }; \
	echo "New partitions mounted."; \
	sleep 2

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
	@# Re-determine TARGET_DRIVE from USB_DEVICE_NAME
	@if [ -z "$(USB_DEVICE_NAME)" ]; then \
		echo "ERROR: USB_DEVICE_NAME not set. Please specify it when running make." >&2; \
		exit 1; \
	fi
	@TARGET_DRIVE="/dev/$(USB_DEVICE_NAME)"; \
	NEW_ROOT_PARTUUID=$$(sudo blkid -s PARTUUID -o value "$${TARGET_DRIVE}2"); \
	if [ -z "$${NEW_ROOT_PARTUUID}" ]; then \
		echo "ERROR: Could not get PARTUUID for new root partition." >&2; \
		exit 1; \
	fi; \
	CMDLINE_TXT_PATH="$(NEW_BOOT_MNT)/cmdline.txt"; \
	if [ ! -f "$${CMDLINE_TXT_PATH}" ]; then \
		echo "ERROR: $${CMDLINE_TXT_PATH} not found. Copying might have failed." >&2; \
		exit 1; \
	fi

	@sudo sed -i "s|root=PARTUUID=[0-9a-fA-F-]\{8\}-[0-9a-fA-F]\{2\}|root=PARTUUID=$${NEW_ROOT_PARTUUID}|" "$${CMDLINE_TXT_PATH}" || { echo "ERROR: Failed to update cmdline.txt." >&2; exit 1; }
	@echo "cmdline.txt updated with new root PARTUUID."
	@echo "--- Configuring fstab ---"
	@# Get all PARTUUIDs for the new partitions
	@TARGET_DRIVE="/dev/$(USB_DEVICE_NAME)"; \
	NEW_BOOT_PARTUUID=$$(sudo blkid -s PARTUUID -o value "$${TARGET_DRIVE}1"); \
	NEW_ROOT_PARTUUID=$$(sudo blkid -s PARTUUID -o value "$${TARGET_DRIVE}2"); \
	NEW_HOME_PARTUUID=$$(sudo blkid -s PARTUUID -o value "$${TARGET_DRIVE}3"); \
	if [ -z "$${NEW_BOOT_PARTUUID}" ] || [ -z "$${NEW_ROOT_PARTUUID}" ] || [ -z "$${NEW_HOME_PARTUUID}" ]; then \
		echo "ERROR: Could not get all PARTUUIDs for new partitions." >&2; \
		exit 1; \
	fi; \
	echo "Writing new fstab..."; \
	{ echo "# This is /etc/fstab for the new Raspberry Pi OS installation."; \
	echo "# Please keep this file in sync with the /etc/fstab file of the"; \
	echo "# system that mounted this file."; \
	echo "# For more info, see fstab(5)."; \
	echo ""; \
	echo "# /boot partition"; \
	echo "PARTUUID=$${NEW_BOOT_PARTUUID} /boot           vfat    defaults,noatime  0       2"; \
	echo ""; \
	echo "# / (root) partition"; \
	echo "PARTUUID=$${NEW_ROOT_PARTUUID} /               ext4    defaults,noatime  0       1"; \
	echo ""; \
	echo "# /home partition"; \
	echo "PARTUUID=$${NEW_HOME_PARTUUID} /home           ext4    defaults,noatime  0       2"; \
	echo ""; \
	echo "# /var as tmpfs (RAM-based, volatile for power-cut resilience)"; \
	echo "tmpfs /var              tmpfs   defaults,noatime,nosuid,size=$(VAR_TMPFS_SIZE_MIB)M        0       0"; \
	echo ""; \
	echo "# /tmp as tmpfs (RAM-based, volatile)"; \
	echo "tmpfs /tmp              tmpfs   defaults,noatime,nosuid,size=64M         0       0"; \
	echo ""; \
	echo "# Swap file (will be created on /home)"; \
	echo "/home/swapfile none swap defaults 0 0"; } | sudo tee "$(NEW_ROOT_MNT)/etc/fstab" > /dev/null || { echo "ERROR: Failed to write fstab." >&2; exit 1; }
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
