# Additional learning from operational events

## Taking a disk offline on purpose
`zpool offline [pool] <disk>`
This does not trigger sparing.

## Replace an offline disk with a spare
`zpool replace [pool] <old device> <new_device>`
If you get `the kernel failed to rescan the partition table` from the new device, you may need to clear it with:
```
dd if=/dev/zero of=/dev/<new device> bs=512 count=1
zpool labelclear <new device>
zpool replace [pool] <old> <new>
zpool status
```

## Drive brown-out
We had a drive that was throwing errors like this:
```
sd 0:0:5:0: [sdf] tag#25 FAILED Result: hostbyte=DID_OK driverbyte=DRIVER_SENSE
sd 0:0:5:0: [sdf] tag#25 Sense Key : Hardware Error [current] 
sd 0:0:5:0: [sdf] tag#25 Add. Sense: No defect spare location available
sd 0:0:5:0: [sdf] tag#25 CDB: Read(10) 28 00 00 00 08 e0 00 00 08 00
blk_update_request: critical target error, dev sdf, sector 2277
Buffer I/O error on dev sdf1, logical block 28, async page read
```
ZFS did *NOT* fail this drive. Not sure why.

## drive labels
During pool creation, drive ids should be used, and not traditional device paths. However, this is a pain as the ids are commonly very long. The best way to deal with this is to create the zpool as normal, export it, and then re-import the pool from the devices in /dev/disk/by-id like this:
```
zpool export <pool>
zpool import -d /dev/disk/by-id <pool>
```
This should result in a zpool with vdevs named after the disk ids, which only change when the disks themselves change. This protects against any device re-ordering for any reason.
