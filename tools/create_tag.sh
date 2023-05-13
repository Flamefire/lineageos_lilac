#!/usr/bin/env bash

set -euo pipefail

GREEN='\033[0;32m'
LGREEN='\033[1;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

current_dir="$(pwd)"
tag_name="${1:-show}"
[[ "$tag_name" == "show" ]] || tag_msg="$2"

my_branch=$(repo info --local-only device/sony/lilac | grep -F 'Manifest revision: ' | sed 's/Manifest revision: //' | sed 's|.*/||')
echo "Current branch: $my_branch"

for p in device/sony/lilac vendor/sony/lilac device/sony/yoshino-common kernel/sony/msm8998; do
    cd "$current_dir/$p"
    if [[ "$tag_name" == "show" ]]; then
        git fetch github &> /dev/null
        status=$(LC_ALL=C git status)
        if echo "$status" | grep -q '^On branch '"$my_branch" && echo "$status" | grep -qF 'nothing to commit, working tree clean'; then
            echo -en "${LGREEN}READY: ${NC}"
        else
            echo -en "${RED}CHANGED: ${NC}"
        fi
    fi
    echo -en "${YELLOW}$p${NC}: " && git -c color.status=always status
    if [[ "$tag_name" != "show" ]]; then
        git tag -a "$tag_name" -m "$tag_msg"
        git push github "$tag_name"
    fi
done
