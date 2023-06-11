MY_LINEAGE_ROOT="$(dirname "$PWD")"

defaultOutPath="$(readlink -f "$MY_LINEAGE_ROOT/out")"
certPath="$(readlink -f "$MY_LINEAGE_ROOT/android-certs")"
systemImgPath="$(readlink -f "$MY_LINEAGE_ROOT/SystemImg")"

export LINEAGE_DEV_CERTIFICATE=vendor/certs/releasekey
export LINEAGE_VERITY_CERTIFICATE=vendor/certs/verity
#export PRODUCT_ADB_KEYS=~/.android/adbkey.pub
export USE_CCACHE=1
export CCACHE_EXEC=$(which ccache)
export OUT_DIR_COMMON_BASE=${OUT_DIR_COMMON_BASE:-$defaultOutPath}
num_procs=$(nproc)

function ensure_folder_symlink {
  path="$1"
  dir="$(dirname "$path")"
  src="$MY_LINEAGE_ROOT/repo19/$path"
  [ -e "$src" ] || src="$MY_LINEAGE_ROOT/repo18/$path"
  for d in "$dir" "$src"; do
    if [ ! -d "$d" ]; then
      echo "Missing $d!"
      return 1
    fi
  done
  [ -e "$path" ] || (cd "$(dirname "$path")" && ln -s "$src")
}

function ensure_clang {
  version="$1"
  ensure_folder_symlink "prebuilts/clang/host/linux-x86/clang-$version"
}

ensure_clang r416183b1 || return 1 # Kernel Clang (12.0.7)
ensure_clang 3289846 || return 1   # Resource compiler

if [ -d "$certPath" ]; then
  mkdir -p vendor/certs
  cp --no-clobber "$certPath"/* vendor/certs || return 1
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
  device/sony/lilac/patches/applyPatches.sh || return 1
  set +u
  { source build/envsetup.sh && \
	  lunch lineage_lilac-userdebug;
  } || return 1
fi

