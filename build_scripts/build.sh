#!/bin/env bash

set -eu

while (($# > 0)); do
    case "$1" in
        --clean)
            export CLEAN_BUILD=1;;
        --skip-extract|--noextract|--no-extract)
            export SKIP_EXTRACT=1;;
        --skip-lfs|--nolfs|--no-lfs)
            export CHECK_LFS=0;;
        --fast)
            export SKIP_EXTRACT=1
            export CHECK_LFS=0
            export CHECK_KERNEL_CFG=0;;
        *)
            echo "Invalid option: $@" >&2; exit 1;;
    esac
    shift
done

source "$(dirname "${BASH_SOURCE[0]}")/setup.sh"
source "$(dirname "${BASH_SOURCE[0]}")/buildAndChecksum.sh"
