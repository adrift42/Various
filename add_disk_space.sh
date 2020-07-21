#!/bin/bash
#
# Adding space to a server drive - via puppet task
# Can be converted to a normal script by changing the 
# various $PT_ variables to normal variables
#
# Date: 	  20/11/2019
# Author: 	Jasper Connery
#
# Updated:  05/12/2019
#   added check to exit script if server contains drives with more than 1 partition - to be removed
#
# TODO:
#	add partition type as an option
# add logic to handle multiple partitions

echo '----------------------'
echo ' Current disk info:'
echo '----------------------'
lsblk
df -h
echo
echo '----------------------'
echo 'Variable examples:'
echo "drive_block='sdd'"
echo "drive_block_partition='1'"
echo "increase_mount_size='10G' or '50%FREE'"
echo "drive_mount='vg02-opt'"
echo '----------------------'
echo 'Exiting...'

# if this is true, exit script after displaying block devices and size usage
if $PT_display_only; then
  exit 0;
fi

# Check if any drives have more than one partition - if so, exit script as 
# this is not yet designed to handle multiple partitions
if partprobe -s | awk -F 'partitions' '{print $2}' | grep 2; then
  echo 'Warning, this script is not designed to handle drives with more than 1 partition.'
  echo 'Please manually update the disk space. Exiting script now...'
  exit 1;
fi

# Variable examples:
#	drive_block='sdd'
#	drive_block_partition='sdd1'
#	increase_mount_size='10G' or '50%FREE'
#	drive_mount='vg02-opt'

drive_block=$PT_drive_block
drive_block_partition="${drive_block}${PT_drive_block_partition}"
increase_mount_size=$PT_increase_mount_size
drive_mount=$PT_drive_mount

original_mount_space=$(df -h | grep "${drive_mount} " | awk {'print $2'})

if [[ $increase_mount_size =~ '%' ]]; then
  disk_extend="-l+${increase_mount_size}"
else
  disk_extend="-L+${increase_mount_size}"
fi

# This allows the server to pick up the new drive size without requiring a reboot
echo 1 > /sys/class/block/$drive_block/device/rescan

# fdisk echo explanations:
# 'd' deletes the current partition 
# 'n' creates a new partition 
# the 4 blank echos choose the default values for (in order):
# 	primary partition 
#	partition number
#	first block sector 
#	last block sector
#
# 't' allows the choosing of the partition type
# '8e' sets the partition type to Linux LVM
# 'w' writes and saves these changes

(echo d; echo n; echo ; echo ; echo ; echo ; echo t; echo 8e; echo w;) | fdisk /dev/$drive_block

# Have the server pick up the new partition details
partprobe

# Resize the drive block partition
pvresize /dev/$drive_block_partition

# Extend the mountpoint
lvextend -r $disk_extend /dev/mapper/$drive_mount

current_mount_space=$(df -h | grep "${drive_mount} " | awk {'print $2'})

# List block devices and report system disk space usage 
echo '--------------------------------'
echo
echo "Drive ${drive_block_partition} is now updated."
echo " Original size: ${original_mount_space}"
echo " New size:      ${current_mount_space}"
echo
echo '--------------------------------'
echo ' Disk info:'
echo '--------------------------------'
lsblk
df -h
