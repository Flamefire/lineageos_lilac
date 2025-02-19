#! /usr/bin/env bash

set -eu

function printStatus () {
  echo ">> [$(date)] $*" >&2
}

export WITH_GMS="true"
export RELEASE_TYPE="MICROG"

if [ ! -e "vendor/partner_gms/products/gms.mk" ]; then
  printStatus "Missing GMS files!"
  exit 1
fi

function reset_patches {
  # Remove previous changes (if they exist)
  for path in "vendor/lineage"; do
    if [ -d "$path" ]; then
      printStatus "Removing changes to $path"
      (cd "$path"; git reset -q --hard; git clean -q -fd)
    fi
  done
}

reset_patches
# Ensure source dir is clean on exit
trap 'reset_patches' EXIT

makefile_containing_version="vendor/lineage/config/common.mk"
if [ -f "vendor/lineage/config/version.mk" ]; then
  makefile_containing_version="vendor/lineage/config/version.mk"
fi
printStatus "Patching build type check in $makefile_containing_version"
sed -i "/\$(filter .*\$(LINEAGE_BUILDTYPE)/,/endif/d" "$makefile_containing_version"

set +e
"$(dirname "${BASH_SOURCE[0]}")/build.sh" "$@"
exit_code=$?
printStatus "Build done"

exit $exit_code
