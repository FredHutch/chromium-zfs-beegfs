# chromium-zfs-beegfs
Full configuration of FredHutch Scratch File System using Commodity Disks, Ubuntu ZFS and BeeGFS


Step by Step install
--------------------

- describe configuration choices 
- only provide details where you are making config changes instead of sccepting the defaults 

Sections
--------

* Prereqs, network install 
* Hardware, Diskconfiguration Bios
* OS install, Ubuntu 16.04.2 with Kernel 4.8 & chef bootstrapping with scicomp-base 
* Ubuntu ZFS config, RAID choices and decision 
* BeeGFS install (supports Kernel 4.8), Kernel tuning, etc. 
* Benchmarks / Discussion

put default config files that require changes under 

storage/etc
metadata/etc 

and track changes via github 

We will do chef configurations at a later time. 

