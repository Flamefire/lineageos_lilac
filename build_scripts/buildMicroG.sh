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

makefile_containing_version="vendor/lineage/config/version.mk"
if [ ! -f "$makefile_containing_version" ]; then
  makefile_containing_version="vendor/lineage/config/common.mk"
fi
permissionManifestFile=frameworks/base/core/res/AndroidManifest.xml

function reset_patches {
  # Remove previous changes (if they exist)
  for path in "$makefile_containing_version" "$permissionManifestFile"; do
    printStatus "Removing changes to $path"
    git -C "$(dirname "$path")" checkout "$(basename "$path")"
  done
}

reset_patches
# Ensure source dir is clean on exit
trap 'reset_patches' EXIT

# Ensure FAKE_PACKAGE_SIGNATURE permission is recognized even though it isn't actually implemented.
# It is still requested by MicroG (granted by privapp-permissions-xml) and might be verified on first boot.
# If it isn't known the app will be terminated preventing the system from booting.
permission='<permission android:name="android.permission.FAKE_PACKAGE_SIGNATURE" android:protectionLevel="signature|privileged" />'
printStatus "Adding FAKE_PACKAGE_SIGNATURE to $permissionManifestFile"
sed -i "0,\#^\s*<permission#s##<!-- @hide --> $permission\n&#" "$permissionManifestFile"

printStatus "Patching build type check in $makefile_containing_version"
sed -i "/\$(filter .*\$(LINEAGE_BUILDTYPE)/,/endif/d" "$makefile_containing_version"

set +e
"$(dirname "${BASH_SOURCE[0]}")/build.sh" "$@"
exit_code=$?
printStatus "Build done"

exit $exit_code
