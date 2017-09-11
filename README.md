# chromium-zfs-beegfs
Full configuration of FredHutch Scratch File System using commodity servers & disks, Ubuntu ZFS and BeeGFS

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

Each storage node (Supermicro SC847) contains: 
* 34 2TB SATA drives (/dev/sd[a-z] + /dev/sda[a-g] intended for ZFS data)
* 2 240GB SSDs (/dev/sda[ij] formatted as mdraid RAID1/ext4 and used for boot/OS)
* 2 200GB SSDs (/dev/sda[kl] intended for ZFS intent log)
* 2 400GB SSDs (/dev/sda[mn] intended for ZFS cache)

Install ZFS utilities from Ubuntu 16.04.1 LTS standard repositories:

`apt install zfsutils-linux`

In ZFS, RAIDZ2 is much like RAID6 in that 2 drives in each group can fail without risk to data. It requires more computation than RAIDZ or conventional RAID5, but these storage nodes are well configured with available, fast CPU cores.

**Note:** the following ZFS commands are available in a unified script `beegfs-zfs-storage.sh` in this repository

Configure each BeeGFS storage node with 3 RAIDZ2 groups, each group with 11 drives:
```
zpool create -f chromium_data raidz2 /dev/sda /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg /dev/sdh /dev/sdi /dev/sdj /dev/sdk

zpool add -f chromium_data raidz2 /dev/sdl /dev/sdm /dev/sdn /dev/sdo /dev/sdp /dev/sdq /dev/sdr /dev/sds /dev/sdt /dev/sdu /dev/sdv

zpool add -f chromium_data raidz2 /dev/sdw /dev/sdx /dev/sdy /dev/sdz /dev/sdaa /dev/sdab /dev/sdac /dev/sdad /dev/sdae /dev/sdaf /dev/sdag
```

Allocate the remaining SATA drive, `/dev/sdah`, as a global spare to the ZFS pool:

`zpool add -f chromium_data spare /dev/sdah`

Allocate the pair of 200GB SSDs, `/dev/sda[kl]`, as ZFS intent log, mirrored for integrity:

`zpool add -f chromium_data log mirror /dev/sdak /dev/sdal`

Allocate the pair of 400GB SSDs, `/dev/sda[mn]`, as ZFS cache:

`zpool add -f chromium_data cache /dev/sdam /dev/sdan`

The cache pair is individually added to maximize space rather than mirrored as cache is checksummed.

With the ZFS pool successfully created and populated, create a file system with LZ4 compression enabled:

`zfs create -o compression=lz4 chromium_data/beegfs_data`

### BeeGFS Installation and Configuration
All nodes - storage, metadata, management (and client) will have BeeGFS installed.  
In the described system, metadata and management share the same physical node.

#### All Node Types
Retrieve the current BeeGFS distribution list for Debian (and related distributions like Ubuntu):

`wget http://www.beegfs.com/release/latest-stable/dists/beegfs-deb8.list`

Copy the retrieved distribution list file into each node's package sources directory:

`cp beegfs-deb8.list /etc/apt/sources.list.d/`

Add key (optional but seems wise):

`wget -q http://www.beegfs.com/release/latest-stable/gpg/DEB-GPG-KEY-beegfs -O- | apt-key add -`

Update the configured repositories:

`apt update`

#### Storage Node(s)
Hostnames: chromium-store*n*
Install storage package(s):

`apt install beegfs-storage`

Edit `/etc/beegfs/beegfs-storage.conf`, altering the 2 following lines to match:
```
sysMgmtdHost = chromium-meta
storeStorageDirectory = /chromium_data/beegfs_data
```
Edit `/lib/systemd/system/beegfs-storage.service` uncommenting the line containing the `PIDFile` settings.
Then reload systemd by running `systemctl daemon-reload`.
This will enable proper systemd management of the beegfs-storage service.

#### Metadata Node(s)
Hostname: chromium-meta
Install metadata package(s):

`apt install beegfs-meta`

Create metadata directory:

`mkdir -p /var/beegfs/meta`

Edit `/etc/beegfs/beegfs-meta.conf`, altering the 2 following lines to match:
```
sysMgmtdHost  = chromium-meta
storeMetaDirectory  = /var/beegfs/meta
```
Edit `/lib/systemd/system/beegfs-meta.service` uncommenting the line containing the `PIDFile` settings.
Then reload systemd by running `systemctl daemon-reload`.
This will enable proper systemd management of the beegfs-meta service.

#### Management Node
Hostname: chromium-meta
Install management package(s):

`apt install beegfs-mgmtd beegfs-utils`

Create storage location for management logging:

`mkdir -p /var/beegfs/mgmt`

Edit `/etc/beegfs/beegfs-mgmt.conf,`, altering the following lines to match:
```
storeMgmtdDirectory  = /var/beegfs/mgmt
logLevel                               = 3
```
Edit `/lib/systemd/system/beegfs-mgmtd.service` uncommenting the line containing the `PIDFile` settings.
Then reload systemd by running `systemctl daemon-reload`.
This will enable proper systemd management of the beegfs-mgmtd service.

**Note:** if client not installed, create `/etc/beegfs/beegfs-client.conf` containing:
```
sysMgmtdHost = chromium-meta
``` 
This allows the use of `beegfs-ctl` without client installation.

#### Client Node(s)
Hostnames: gizmo*n*, rhino*n*, chromium-meta(different conf)
Install client package(s):

`apt-get install beegfs-client beegfs-helperd beegfs-utils`

Note: This will pull in many other packages as the client requires a kernel module to be built.

Build client kernel module:

`/etc/init.d/beegfs-client rebuild`

Edit `/etc/beegfs/beegfs-client.conf`, altering the following line to match:
```
sysMgmtdHost  = chromium-meta
```

Edit `/etc/beegfs/beegfs-mounts.conf` to specify where to mount BeeGFS.

The first column is the mount point, e.g. /mnt/beegfs

The second column is the client configuration file for that mount point, e.g. `/etc/beegfs/beegfs-client.conf`

##### Special instructions to install new BeeGFS 6 client on existing FhGFS node for migration

FhGFS and BeeGFS have different client names, configuration directories/files and kernel modules.  With appropriate configuration they can both be installed and function properly on the same node.  This is helpful in easing migration from old to new scratch file systems.

BeeGFS 6 should be installed explicitly from packages via `dpkg` rather than be added to apt.  Though the existing nodes are Ubuntu 14.04.02 LTS (identifying themselves as debian jessie/sid - deb8), BeeGFS **deb7 packages must be installed** instead due to version mismatches.

Get client packages from BeeGFS site or previously installed node and install in order:
```
dpkg -i beegfs-opentk-lib_6.11-debian7_amd64.deb 
dpkg -i beegfs-common_6.11-debian7_amd64.deb
dpkg -i beegfs-helperd_6.11-debian7_amd64.deb
dpkg -i beegfs-client_6.11-debian7_all.deb
```
Edit config files to avoid conflicts with existing FhGFS client:

Edit `/etc/beegfs/beegfs-client.conf`, altering the following lines to match:
```
sysMgmtdHost                  = chromium-meta
connClientPortUDP             = 8014
connHelperdPortTCP            = 8016
```

Edit `/etc/beegfs/beegfs-helperd.conf`, altering the following line to match:
```
connHelperdPortTCP = 8016
```

### BeeGFS Startup and Verification

#### Management Node
```
/etc/init.d/beegfs-mgmtd start
```

#### Metadata Node(s)
```
/etc/init.d/beegfs-meta start
```

#### Storage Node(s)
```
/etc/init.d/beegfs-storage start
```

#### Client Node(s)
```
/etc/init.d/beegfs-helperd start
/etc/init.d/beegfs-client start
```

#### Verification
There are two utilities that can be used to verify that all BeeGFS components are running and visible.  Both should be accessible from the management server.

`beegfs-check-servers` will show all reachable node types and their BeeGFS system IDs.

This program is actually a wrapper for the more general `beegfs-ctl`.

`beegfs-ctl` without parameters will provide a list of its many options.  This tool can be used to:
* list cluster components
* delete nodes
* explicitly migrate data between storage servers
* display system stats
* configure redundancy
* run read/write benchmarks
* and much, much more

Further information and debugging can be done with the aid of BeeGFS log files on each node.  These have been configured to reside in /var/log/beegfs-[storage,mgmtd,meta] on each server type.


### File Management 

The scratch file system has 3 folders, delete10, delete30, delete90. Files are deleted when mtime, atime AND ctime are greater than 10, 30 or 90 days from the current date. Each folder contains a work folder per Principal Investigator with the naming convention lastname_f

#### fs-cleaner deletes unused files 

/etc/cron.d/fs-cleaner-scratch has 3 cron jobs that execute fs-cleaner daily for delete10, delete30 and delete90 and removes older files or sends warning emails about files to be deleted. (see https://github.com/FredHutch/fs-cleaner)


#### createPIfolders 

/etc/cron.d/new-pi-folders has 3 cron jobs that trigger createPIfolders, an internal shell script that looks for existance of AD security groups and creates folders for each PI that has a security group for accessing the posix file system

 









