#!/bin/env bash
set -euo pipefail

old_cwd=$(pwd)

for dir in "$@"; do
    cd "$dir"
    name=$(repo info . | grep 'Project:' | cut -d ' ' -f2)
    name=${name#LineageOS/}
    name=${name//\//_}
    echo "# PWD: $dir" > /tmp/$name.patch
    git diff m/lineage-17.1 >> /tmp/$name.patch
    cd "$old_cwd"
done
