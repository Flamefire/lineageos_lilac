#!/bin/env bash
set -euo pipefail

policy="$(mktemp)"
trap 'rm -rf -- "$policy"' EXIT

adb pull /sys/fs/selinux/policy "$policy"
adb logcat -b all -d | audit2allow -p "$policy"
