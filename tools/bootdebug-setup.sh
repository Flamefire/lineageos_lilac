#!/usr/bin/env bash

set -eu

cat << 'EOF' > device/sony/yoshino-common/config/init/init.log.sh
#! /vendor/bin/sh

_date=`date +%F_%H-%M-%S`
logcat -b all 2>&1 > /cache/logcat_${_date}.txt &
cat /proc/kmsg > /cache/kmsg_${_date}.txt

exit 0
EOF
chmod +x device/sony/yoshino-common/config/init/init.log.sh

echo 'PRODUCT_COPY_FILES += $(PLATFORM_PATH)/config/init/init.log.sh:$(TARGET_COPY_OUT_VENDOR)/bin/init.log.sh' \
    >> device/sony/yoshino-common/platform/init-files.mk

cat << 'EOF' >> device/sony/yoshino-common/config/init/init.yoshino.rc

service logx /vendor/bin/init.log.sh
    user root
    group root system
    seclabel u:r:su:s0
    oneshot

on post-fs
    start logx
EOF

echo 'BOARD_KERNEL_CMDLINE += androidboot.selinux=permissive' >> device/sony/yoshino-common/BoardConfigPlatform.mk
