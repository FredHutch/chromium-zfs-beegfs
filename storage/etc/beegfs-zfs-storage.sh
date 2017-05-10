#!/bin/bash
# ------------------------------------------------------------------
# Configure FHCRC BeeGFS Storage Node ZFS
#          Assumes drive configuration == chromium-store[5-8]!
# ------------------------------------------------------------------
#
echo "This script will create a ZFS pool and export a filesystem"
read -p "Are you sure? (Y/n)" -n 1 -r
echo    # (optional) move to a new line
if [[ ! $REPLY =~ ^Y$ ]]
then
	exit 1
fi

# configure 3 RAIDZ2 groups of 11 drives
zpool create -f chromium_data raidz2 /dev/sda /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk
#
zpool add -f chromium_data raidz2 /dev/sdl /dev/sdm /dev/sdn /dev/sdo /dev/sdp /dev/sdq /dev/sdr /dev/sds /dev/sdt /dev/sdu /dev/sdv
#
zpool add -f chromium_data raidz2 /dev/sdw /dev/sdx /dev/sdy /dev/sdz /dev/sdaa /dev/sdab /dev/sdac /dev/sdad /dev/sdae /dev/sdaf /dev/sdag
#
# Configure 1 global spare drive
zpool add -f chromium_data spare /dev/sdah
#
# Configure ZIL
zpool add -f chromium_data log mirror /dev/sdak /dev/sdal
#
# Configure cache
zpool add -f chromium_data cache /dev/sdam /dev/sdan
#
# Create BeeGFS LZ4 compressed file system
zfs create -o compression=lz4 chromium_data/beegfs_data
