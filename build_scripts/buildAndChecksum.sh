set -eu

source "$(dirname "${BASH_SOURCE[0]}")/setup.sh"

GREEN='\033[0;32m'
LGREEN='\033[1;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

targetFileName="lineage-$(get_build_var LINEAGE_VERSION).zip"
targetFile="$ANDROID_PRODUCT_OUT/$targetFileName"

echo -e "${GREEN}Building ${YELLOW}${targetFile}${NC}"

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
            echo -e "Copy ${YELLOW}$old_name ${NC} to ${YELLOW} $new_name${NC}"
            cp -a "$f" "$(dirname "$f")/$new_name"
        else
            echo -e "Move ${YELLOW}$old_name ${NC} to ${YELLOW} $new_name${NC}"
            mv "$f" "$(dirname "$f")/$new_name"
        fi
    done
fi

if [ "${CLEAN_BUILD:-0}" == "1" ]; then
    echo -e "${YELLOW}Cleaning build dir"
    mka installclean
fi

echo -e "${YELLOW}Starting build...${NC}"

if mka bacon; then
    outDir="$OUT_DIR_COMMON_BASE/$(basename "$PWD")"
    if [ "${CHECK_LFS:-1}" == "1" ] && grep -rF --files-with-matches "https://git-lfs." "$outDir"; then
        echo -e "${RED}Found git LFS files in $outDir!${NC}" && false
    fi

    otaFiles=( "$ANDROID_PRODUCT_OUT/$(get_build_var TARGET_PRODUCT)-ota-"*.zip )
    otaFile=${otaFiles[0]}
    if [ -e "$otaFile" ]; then
        echo -e "${YELLOW}Removing OTA file $otaFile...${NC}"
        rm "$otaFile"
    fi
    if is_hardlink "$targetFile"; then
        echo -e "${YELLOW}Un-hardlink $targetFile...${NC}"
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
    mv "$targetFile"* "$OUT_DIR_COMMON_BASE"
    echo "Moved $(md5sum "$OUT_DIR_COMMON_BASE/$targetFileName")"
else
    echo "Failed to build" && false
fi
