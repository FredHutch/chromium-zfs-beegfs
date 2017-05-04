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

### Ubuntu ZFS Installation and Configuration
Each BeeGFS **storage node** is configured with ZFS for several reasons including: 
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

Install ZFS utilities from Ubuntu 16.04.1 LTS standard repositories:

`apt install zfsutils-linux`

In ZFS, RAIDZ2 is much like RAID6 in that 2 drives in each group can fail without risk to data. It requires more computation than RAIDZ or conventional RAID5, but these storage nodes are well configured with available, fast CPU cores.

Configure each BeeGFS storage node with 3 RAIDZ2 groups, each group with 11 drives:
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

### BeeGFS Installation and Configuration
All nodes, storage, metadata and management will have BeeGFS installed.  In the described system, metadata and management share the same physical node.

#### All Nodes
Retrieve the current BeeGFS distribution list for Debian (and related distributions like Ubuntu):

`wget http://www.beegfs.com/release/latest-stable/dists/beegfs-deb8.list`

Copy the retrieved distribution list file into each node's package sources directory:

`cp beegfs-deb8.list /etc/apt/sources.list.d/`

Add key (optional but seems wise):

`wget -q http://www.beegfs.com/release/latest-stable/gpg/DEB-GPG-KEY-beegfs -O- | apt-key add -`

Update the configured repositories:

`apt update`

#### Storage Node(s)
Install storage package(s):

`apt install beegfs-storage`

Edit `/etc/beegfs/beegfs-storage.conf`, altering the 2 following lines to match:
```
sysMgmtdHost = chromium-meta
storeStorageDirectory = /chromium_data/beegfs_data
```

#### Metadata Node(s)
Install metadata package(s):

`apt install beegfs-meta`

Edit `/etc/beegfs/beegfs-meta`, altering the 2 following lines to match:
```
sysMgmtdHost  = chromium-meta
storeMetaDirectory  = /chromium-metadata
```

#### Management Node
Install management package(s):

`apt install beegfs-mgmtd beegfs-utils`

Create storage location for management logging:

`mkdir /var/beegfs`

Edit `/etc/beegfs/beegfs-mgmt`, altering the following line to match:
```
storeMgmtdDirectory  = /var/beegfs
```

**Note:** create `/etc/beegfs/beegfs-client.conf` containing:
```
sysMgmtdHost = chromium-meta
``` 
This allows the use of `beegfs-ctl` without requiring client installation.

## Other

put default config files that require changes under 

storage/etc
metadata/etc 

and track changes via github 

We will do chef configurations at a later time. 

