set -eu

function _get_build_var {
    set +u
    if [[ $(type -t get_build_var) != "function" ]]; then
        source build/envsetup.sh
    fi
    get_build_var "$@"
    set -u
}

: "${num_procs:=$(nproc)}"
GREEN='\033[0;32m'
LGREEN='\033[1;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

targetFileName="lineage-$(_get_build_var LINEAGE_VERSION).zip"
targetFile="$ANDROID_PRODUCT_OUT/$targetFileName"

function is_hardlink {
    [[ $(stat --printf '%h' "$1") != 1 ]]
}

if [ -e "$targetFile" ]; then
    echo -e "${RED}Moving old build file ${LGREEN}$(basename "$targetFile")${NC}"
    rm -f "$targetFile.bak"*
    for f in "$targetFile"*; do
        old_name="$(basename "$f")"
        new_name="${old_name/.zip/.bak.zip}"
    if is_hardlink "$f"; then
        cp -a "$f" "$(dirname "$f")/$new_name"
    else
        mv "$f" "$(dirname "$f")/$new_name"
    fi
    done
fi

if [ "${CLEAN_BUILD:-0}" == "1" ]; then
    echo -e "${YELLOW}Cleaning build dir"
    make installclean
fi

echo -e "${YELLOW}Starting build with ${GREEN}$((num_procs + 1))x${YELLOW} parallel${NC}"

if make -j$((num_procs + 1)) bacon; then
    outDir="$OUT_DIR_COMMON_BASE/$(basename "$PWD")"
    if grep -rF --files-with-matches "https://git-lfs." "$outDir"; then
        echo -e "${RED}Found git LFS files in $outDir!${NC}" && false
    fi

    otaFile="$ANDROID_PRODUCT_OUT/$(_get_build_var TARGET_PRODUCT)-ota-"*.zip
    [ ! -e "$otaFile" ] || rm "$otaFile"
    if is_hardlink "$targetFile"; then
        tmpFile="$(mktemp -p /dev/shm)"
        cp -af "$targetFile" "$tmpFile"
        mv -f "$tmpFile" "$targetFile"
    fi

    cs="$(cd "$ANDROID_PRODUCT_OUT" && md5sum "$targetFileName")"
    echo -e "${LGREEN}Created ${YELLOW}${targetFile}${LGREEN}, checksum=${YELLOW}${cs% *}${NC}"
    echo "$cs" > "$targetFile.md5sum"
    cs_f="$targetFile.sha256sum"
    [ ! -e "$cs_f" ] || rm "$cs_f"

    if [ "${CHECK_KERNEL_CFG:-1}" == "1" ]; then
        kernel/sony/msm8998/scripts/extract-ikconfig "$ANDROID_PRODUCT_OUT/kernel" | diff kernel/sony/msm8998/arch/arm64/configs/lineage-msm8998-yoshino-lilac_defconfig -
    fi
    (cd "$ANDROID_PRODUCT_OUT" && md5sum lineage-*.zip)
else
    echo "Failed to build" && false
fi
