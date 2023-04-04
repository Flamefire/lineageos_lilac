#! /usr/bin/env bash

set -eu

function printStatus () {
  echo ">> [$(date)] $@" >&2
}

export WITH_GMS="true"
export RELEASE_TYPE="MICROG"
#export SKIP_EXTRACT="1"

if [ ! -e "vendor/partner_gms/products/gms.mk" ]; then
  printStatus "Missing GMS files!"
  exit 1
fi

branch=$(repo info | sed -ne 's/Manifest branch: refs\/heads\///p' | sed 's/[^[:alnum:]]/_/g')

vendor=lineage
case "$branch" in
  lineage_17_1)
    frameworks_base_patch="android_frameworks_base-Q.patch"
    ;;
  lineage_18_1)
    frameworks_base_patch="android_frameworks_base-R.patch"
    ;;
  lineage_19_1)
    frameworks_base_patch="android_frameworks_base-S.patch"
    ;;
  *)
    printStatus "Building branch $branch is not (yet) suppported"
    exit 1
    ;;
esac

printStatus "Branch:  $branch"

PATCH_DIR="/tmp/docker-lineage-cicd-master/src"
if [ ! -d "$PATCH_DIR" ]; then
  printStatus "Downloading lineageos4microg"
  wget https://github.com/lineageos4microg/docker-lineage-cicd/archive/refs/heads/master.tar.gz -O /tmp/master.tar.gz
  (cd /tmp && tar xf master.tar.gz)
  printStatus "Downloaded lineageos4microg"
fi


function reset_patches {
  # Remove previous changes (if they exist)
  for path in "vendor/lineage" "frameworks/base"; do
    if [ -d "$path" ]; then
      printStatus "Removing changes to $path"
      (cd "$path"; git reset -q --hard; git clean -q -fd)
    fi
  done
}

reset_patches

printStatus "Set up MicroG overlay"
_microgOverlayPath="vendor/lineage/overlay/microg"
mkdir -p "$_microgOverlayPath"
sed -i "1s;^;PRODUCT_PACKAGE_OVERLAYS := $_microgOverlayPath\n;" "vendor/lineage/config/common.mk"
# Override device-specific settings for the location providers
_microgOverlayPath+="/frameworks/base/core/res/res/values"
mkdir -p "$_microgOverlayPath"
cp $PATCH_DIR/signature_spoofing_patches/frameworks_base_config.xml "$_microgOverlayPath/config.xml"

makefile_containing_version="vendor/lineage/config/common.mk"
if [ -f "vendor/lineage/config/version.mk" ]; then
  makefile_containing_version="vendor/lineage/config/version.mk"
fi
printStatus "Patching build type check in $makefile_containing_version"
sed -i "/\$(filter .*\$(LINEAGE_BUILDTYPE)/,/endif/d" "$makefile_containing_version"

printStatus "Applying the restricted signature spoofing patch (based on $frameworks_base_patch) to frameworks/base"
patchPath="$PATCH_DIR/signature_spoofing_patches/$frameworks_base_patch"
sed 's/android:protectionLevel="dangerous"/android:protectionLevel="signature|privileged"/' "$patchPath" | patch -d frameworks/base --quiet --force -p1 --no-backup-if-mismatch

"$(dirname "${BASH_SOURCE[0]}")/build.sh"

printStatus "Build done"
reset_patches
