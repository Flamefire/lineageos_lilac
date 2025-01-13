#!/bin/env bash
set -euo pipefail

GREEN='\033[0;32m'
LGREEN='\033[1;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

asb_commit=${1:?"No commit specified"}

function showError {
    echo -e "${RED}ERROR: $@${NC}" && false
}

title=$(cd build/make && git show --format=%s --no-patch "$asb_commit")
if [[ "$title" != "Bump Security String"* ]]; then
    showError "Wrong commit? Title: $title"
fi

for ref in $(cd build/make && git show --format=%b --no-patch "$asb_commit" | sed '/Not Applicable/q' | grep -F 'A-' | sed -E 's/.*(A-[0-9]+).*/\1/'); do
    id=${ref#A-}
    echo -en "${YELLOW}$ref"
    commit=$(repo forall -c 'x=$(git log --oneline --grep='"'Bug:.* $id'"'); if [ -n "$x" ]; then pwd && echo "$x"; fi')
    if [ -z "$commit" ]; then
        echo -e " ${RED}Missing${NC}"
    else
        echo -e " ${LGREEN}OK${NC}"
        echo "    $commit"
    fi
done