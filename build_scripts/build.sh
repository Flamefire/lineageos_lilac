#!/bin/env bash

set -eu

while (($# > 0)); do
    case "$1" in
        --clean)
            export CLEAN_BUILD=1;;
        --skip-extract)
            export SKIP_EXTRACT=1;;
        --skip-lfs)
            export CHECK_LFS=0;;
        --skip-patch)
            export SKIP_PATCH=1;;
        --skip-kernel-cfg)
            export CHECK_KERNEL_CFG=0;;
	--skip-tidy)
	    export WITH_TIDY=0
	    ;;
        --fast)
            export SKIP_EXTRACT=1
            export CHECK_LFS=0
            export SKIP_PATCH=1
            export CHECK_KERNEL_CFG=0
            export WITH_TIDY=0
            ;;
	--help|-h)
	    echo "Usage: $0 [--clean] [--skip-extract] [--skip-lfs] [--skip-patch] [--skip-kernel-cfg] [--skip-tidy]"
	    echo "--fast combines --skip-extract --skip-lfs --skip-patch --skip-kernel-cfg --skip-tidy"
	    exit 0;;
        *)
            echo "Invalid option: $@" >&2; exit 1;;
    esac
    shift
done

source "$(dirname "${BASH_SOURCE[0]}")/setup.sh"
source "$(dirname "${BASH_SOURCE[0]}")/buildAndChecksum.sh"
