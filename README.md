# chromium-zfs-beegfs
Full configuration of FredHutch Scratch File System using Commodity Disks, Ubuntu ZFS and BeeGFS


Step by Step install
--------------------

- describe configuration choices 
- only provide details where you are making config changes instead of accepting the defaults 

Sections
--------

* Prereqs, network install 
* Hardware, Diskconfiguration Bios
* OS install, Ubuntu 16.04.2 with Kernel 4.8 & chef bootstrapping with scicomp-base 
* Ubuntu ZFS config, RAID choices and decision 
* BeeGFS install (supports Kernel 4.8), Kernel tuning, etc. 
* Benchmarks / Discussion

### Ubuntu ZFS Configuration
Each BeeGFS storage node is configured on top of ZFS for several reasons including: 
* ease of administration
* well integrated file system and logical volume manager
* integral compression
* sequentialization of disk writes
* and very importantly, elaborate error checking and correction

Each storage node contains: 
* 34 2TB SATA drives (/dev/sd[a-z] + /dev/sda[a-g] intended for ZFS data)
* 2 240GB SSDs (/dev/sda[ij] formatted as mdraid RAID1/ext4 and used for boot/OS)
* 2 200GB SSDs (/dev/sda[kl] intended for ZFS cache)
* 2 400GB SSDs (/dev/sda[mn] intended for ZFS intent log)

Ubuntu 16.04.1 LTS provides ZFS in its standard repositories, enabled for use with:

`apt install zfsutils-linux`

In ZFS, RAIDZ2 is much like RAID6 in that 2 drives in each group can fail without risk to data. It requires more computation than RAIDZ or conventional RAID5, but these storage nodes are well configured with available, fast CPU cores.

Each BeeGFS storage node with 3 RAIDZ2 groups of 11 drives in each ZFS pool, with 1 spare drive.  A list of all available SATA drives was made and each allocated to a RAIDZ2 group:
```
zpool create -f chromium_data raidz2 /dev/sda /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk

zpool add -f chromium_data raidz2 /dev/sdl /dev/sdm /dev/sdn /dev/sdo /dev/sdp /dev/sdq /dev/sdr /dev/sds /dev/sdt /dev/sdu /dev/sdv

zpool add -f chromium_data raidz2 /dev/sdw /dev/sdx /dev/sdy /dev/sdz /dev/sdaa /dev/sdab /dev/sdac /dev/sdad /dev/sdae /dev/sdaf /dev/sdag
```

Allocate the remaining SATA drive, `/dev/sdah`, as a global spare to the ZFS pool:

`zpool add -f chromium_data spare /dev/sdah`

Allocate the pair of 200GB SSDs, `/dev/sda[kl]`, as ZFS cache:

`zpool add -f chromium_data cache /dev/sdak /dev/sdal`

The cache pair is individually added to maximize space rather than mirrored as cache is checksummed.

Allocate the pair of 400GB SSDs, `/dev/sda[mn]`, as ZFS intent log, mirrored for integrity:

`zpool add -f chromium_data log mirror /dev/sdam /dev/sdan`

With the ZFS pool successfully created and populated, create a file system with LZ4 compression enabled:

`zfs create -o compression=lz4 chromium_data/beegfs_data`

### Other

put default config files that require changes under 

storage/etc
metadata/etc 

and track changes via github 

We will do chef configurations at a later time. 

