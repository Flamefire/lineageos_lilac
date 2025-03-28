 # shellcheck shell=bash

MY_LINEAGE_ROOT="$(dirname "$PWD")"

defaultOutPath="$(readlink -f "$MY_LINEAGE_ROOT/out")"
certPath="$(readlink -f "$MY_LINEAGE_ROOT/android-certs")"
systemImgPath="$(readlink -f "$MY_LINEAGE_ROOT/SystemImg")"

export BUILD_USERNAME=android-user
export BUILD_HOSTNAME=r-fffb43f69680a4d8-5631

export LINEAGE_DEV_CERTIFICATE=vendor/certs/releasekey
export LINEAGE_VERITY_CERTIFICATE=vendor/certs/verity
#export PRODUCT_ADB_KEYS=~/.android/adbkey.pub
: "${USE_CCACHE:=1}"
export USE_CCACHE
export CCACHE_EXEC=$(which ccache)
export OUT_DIR_COMMON_BASE=${OUT_DIR_COMMON_BASE:-$defaultOutPath}

function ensure_folder_symlink {
  path="$1"
  if [ -e "$path" ]; then
    return 0
  fi
  dir="$(dirname "$path")"
  src="$MY_LINEAGE_ROOT/repo19/$path"
  [ -e "$src" ] || src="$MY_LINEAGE_ROOT/repo18/$path"
  for d in "$dir" "$src"; do
    if [ ! -d "$d" ]; then
      echo "Missing $d!"
      return 1
    fi
  done
  (cd "$(dirname "$path")" && ln -s "$src" .)
}

function ensure_clang {
  version="$1"
  ensure_folder_symlink "prebuilts/clang/host/linux-x86/clang-$version"
}

manifest_branch=$(grep -F '<default revision=' .repo/manifests/default.xml | sed -E 's|.*"refs/heads/(.*)"|\1|')
if [[ ${manifest_branch#*/} == "lineage-17.1" ]]; then
  ensure_clang r416183b1 || return 1 # Kernel Clang (11.0.7)
  ensure_clang r383902b1 || return 1 # 18.1 Default clang (11.0.2)
  ensure_clang 3289846 || return 1   # Resource compiler
fi

if [ -d "$certPath" ]; then
  mkdir -p vendor/extra/keys
  cp --no-clobber "$certPath"/* vendor/extra/keys || return 1
  if [[ ! -e "vendor/extra/product.mk" ]] || ! grep -qF "PRODUCT_DEFAULT_DEV_CERTIFICATE" vendor/extra/product.mk; then
    echo "PRODUCT_DEFAULT_DEV_CERTIFICATE := vendor/extra/keys/releasekey" >> vendor/extra/product.mk
    echo "PRODUCT_VERITY_SIGNING_KEY := vendor/extra/keys/verity" >> vendor/extra/product.mk
  fi
fi

if [ ! -e "vendor/sony/lilac/lilac-vendor.mk" ]; then
  SKIP_EXTRACT=0
fi

if [ "${CHECK_LFS:-1}" == "1" ] && ! repo forall -c '[ ! -e .lfsconfig ] || git lfs pull'; then
  echo "Git LFS pull failed:"
  repo forall -c 'git lfs pull || pwd'
  sleep 10s
fi

if [ "${SKIP_EXTRACT:-0}" != "1" ] && ! (cd vendor/sony/lilac && git co . && git clean -fd && cd - && cd device/sony/lilac && ./extract-files.sh "$systemImgPath"); then
  echo "Failed to extract files!" && return 1
else
  [ "${SKIP_PATCH:-0}" == "1" ] || device/sony/lilac/patches/applyPatches.sh || return 1
  set +u
  { source build/envsetup.sh && \
	  lunch lineage_lilac-userdebug;
  } || return 1
fi

