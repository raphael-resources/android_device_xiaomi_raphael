#!/system/bin/sh
#
# Copyright (C) 2026 Paranoid Android
#
# SPDX-License-Identifier: Apache-2.0
#

# Boot debugging for a boot that hangs or resets.
#
# ramoops doesn't survive the reset on this device, so the kernel log and
# logcat are streamed to /metadata (ext4, data=journal, commit=1) as they
# are produced. Whatever was logged up to a second before the device froze
# or reset is kept. The last 5 boots are kept, boot0 is the newest.
#
# Every few seconds the stacks of blocked tasks (sysrq-w) and of the
# running CPUs (sysrq-l) are dumped to the kernel log. Anything that can
# block (ps, getprop) runs in the background so the loop keeps going.

BASE=/metadata/raphael-debug

mkdir -p $BASE
rm -rf $BASE/boot4
for n in 3 2 1 0; do
    [ -d $BASE/boot$n ] && mv $BASE/boot$n $BASE/boot$((n + 1))
done
DIR=$BASE/boot0
mkdir -p $DIR

echo 1 > /proc/sys/kernel/sysrq
echo on > /proc/sys/kernel/printk_devkmsg

# Kernel log, the whole ring buffer and then everything new
cat /dev/kmsg > $DIR/kmsg.txt 2>&1 &

# logcat, retried until logd is up
(
    while true; do
        logcat -b all -v threadtime >> $DIR/logcat.txt 2>&1
        sleep 1
    done
) &

i=0
while [ $i -lt 120 ]; do
    echo "raphael-debug: tick $i" > /dev/kmsg
    echo w > /proc/sysrq-trigger
    echo l > /proc/sysrq-trigger
    (
        timeout 4 ps -A -o PID,PPID,STAT,WCHAN,NAME > $DIR/ps.txt.new 2>&1
        mv $DIR/ps.txt.new $DIR/ps.txt
        grep -E " D | R " $DIR/ps.txt | while read l; do
            echo "raphael-debug: $i $l" > /dev/kmsg
        done
        timeout 4 getprop > $DIR/props.txt.new 2>&1
        mv $DIR/props.txt.new $DIR/props.txt
    ) &
    sync
    sleep 5
    i=$((i + 1))
done
