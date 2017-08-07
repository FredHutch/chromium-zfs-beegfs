#!/bin/bash
# ------------------------------------------------------------------
# Apply BeeGFS tunings to FHCRC BeeGFS Storage Node ZFS
#          Assumes drive configuration == chromium-store[5-8]!
# ------------------------------------------------------------------
#
# Set an appropriate IO scheduler for file servers
for drive in {a..z}; do echo deadline >/sys/block/sd$drive/queue/scheduler; done
for drive in {a..h}; do echo deadline >/sys/block/sda$drive/queue/scheduler; done
#
# Increase IO scheduler number of schedulable requests
for drive in {a..z}; do echo 4096 > /sys/block/sd$drive/queue/nr_requests; done
for drive in {a..h}; do echo 4096 > /sys/block/sda$drive/queue/nr_requests; done
#
# Improve sequential read throughput by increasing maximum read-ahead
for drive in {a..z}; do echo 4096 > /sys/block/sd$drive/queue/read_ahead_kb; done
for drive in {a..h}; do echo 4096 > /sys/block/sda$drive/queue/read_ahead_kb; done
#
# Avoid long IO stalls (latencies) for write cache flushing
echo 5 > /proc/sys/vm/dirty_background_ratio
echo 10 > /proc/sys/vm/dirty_ratio
#
# Assigning slightly higher priority to inode caching helps to avoid disk seeks
echo 50 > /proc/sys/vm/vfs_cache_pressure
#
# Raise reserved kernel memory = enable faster/more reliable memory allocation
echo 262144 > /proc/sys/vm/min_free_kbytes
#
# Try to disable automatic frequency scaling
echo performance | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor >/dev/null
