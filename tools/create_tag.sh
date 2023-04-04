#!/usr/bin/env bash

set -euo pipefail

current_dir="$(pwd)"
tag_name="${1:-show}"
[[ "$tag_name" == "show" ]] || tag_msg="$2"

for p in device/sony/lilac vendor/sony/lilac device/sony/yoshino-common kernel/sony/msm8998; do
    cd "$current_dir/$p"
    [[ "$tag_name" != "show" ]] || git fetch github &> /dev/null
    echo "$p: $(git -c color.status=always status)"
    if [[ "$tag_name" != "show" ]]; then
        git tag -a "$tag_name" -m "$tag_msg"
        git push github "$tag_name"
    fi
done
