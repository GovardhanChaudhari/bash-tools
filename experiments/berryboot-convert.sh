#!/bin/bash

# Raspberry Pi OS Lite Image Generator for Berryboot
# Copyright 2018-2021 Alexander G.
# https://www.alexgoldcheidt.com
# https://github.com/agoldcheidt

# Install necessary packages
sudo apt update && sudo apt install -y aria2 unzip util-linux squashfs-tools

if [ "$EUID" -ne 0 ]
then 
    echo 1>&2 "Please run as root"
    exit 1
fi

#date
date=$(date +"%d-%b-%Y")

sleep 1
clear
#Some artwork...
echo "--------------------------------------------------------------"
echo "  ___              _                        ___ _    ___  ___ ";
echo " | _ \__ _ ____ __| |__  ___ _ _ _ _ _  _  | _ (_)  / _ \/ __|";
echo " |   / _\` (_-< '_ \ '_ \/ -_) '_| '_| ||| |  _/ | | (_) \__ \ ";
echo " |_|_\__,_/__/ .__/_.__/\___|_| |_|  \_, | |_| |_|  \___/|___/";
echo "             |_|                     |__/                     ";
echo "--------------------------------------------------------------"

# Name for Converted OS Image
NAME="raspberry_pi_os_latest_lite_berryboot-$date.img"

# Mount Points
MNT1="/mnt/raspberry-pi-os-boot"
MNT2="/mnt/raspberry-pi-os-rootfs"

echo ""
echo "#### RASPBERRY PI OS LITE IMAGE GENERATOR FOR BERRYBOOT ####"
echo ""

# Assuming the image is already downloaded and named "raspberry_pi_os_lite.img"
IMAGE="raspberry_pi_os_lite.img"

echo ""
echo "#### DECOMPRESSING RASPBERRY PI OS LITE IMAGE ####"
echo ""
sudo mkdir -p $MNT1 $MNT2
sudo losetup -P /dev/loop55 $IMAGE
sudo mount /dev/loop55p1 $MNT1
sudo mount /dev/loop55p2 $MNT2
sudo find $MNT2 -name 'cached_UTF-8_del.kmap.gz' -exec sh -c 'rm -f \$1' _ {} \;
sudo find $MNT2 -name 'apply_noobs_os_config.service' -exec sh -c 'rm -f \$1' _ {} \;
sudo find $MNT2 -name 'raspberrypi-net-mods.service' -exec sh -c 'rm -f \$1' _ {} \;
sudo sed -i 's/^\PARTUUID/#\0/g' $MNT2/etc/fstab
sudo rm -f $MNT1/kernel* $MNT1/*.elf
sudo cp -R $MNT1/* $MNT2/boot/
clear
echo ""
echo "#### CONVERTING RASPBERRY PI OS LITE IMAGE TO BERRYBOOT ####"
echo ""
sudo mksquashfs $MNT2 $NAME -comp lzo -e lib/modules var/cache/apt/archives var/lib/apt/lists
sudo umount $MNT1 $MNT2
sudo losetup -d /dev/loop55
sudo rm -rf $MNT1 $MNT2
clear
echo ""
echo "#### RASPBERRY PI OS LITE IMAGE READY! ####"
echo ""
echo "-----------------------------------------------"
echo "Support my project at: paypal.me/alexgoldc"
echo "-----------------------------------------------"
echo ""
