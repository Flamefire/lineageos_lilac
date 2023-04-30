#!/bin/env bash
set -euo pipefail

branch=${1:?"No branch specified"}
old_cwd=$(pwd)

function showError {
    echo -e "\033[0;31mERROR: $@\033[0m" && false
}

if [[ $# == 2 ]]; then
    targetDir="$(readlink -f "$2")"
else
    targetDir="$(mktemp -d)"
fi

targetDir+="/$branch"
[ -d "$targetDir" ] || mkdir "$targetDir"

for dir in $(repo status | grep '^project ' | grep -F "branch $branch" | awk '{print $2}' | sed 's|/$||'); do
    echo "Processing project $dir"
    cd "$old_cwd"
    cd "$dir"

    manifestRev=$(repo info . | grep -F "Manifest revision: " | awk '{print $3}')
    if [[ "$manifestRev" =~ ^refs/heads/.* ]]; then
        manifestRev=${manifestRev/'refs/heads'/m}
    else
        manifestRev="github/$manifestRev"
    fi
    if ! git rev-parse --verify -q "$manifestRev" &> /dev/null; then
        showError "Missing manifest branch: $manifestRev"
    fi
    echo "  Manifest branch: $manifestRev"

    if git branch --list 'asb-*' | grep -qvF -- "$branch"; then
        parentBranch=$(git branch --list 'asb-*' | sort --reverse | grep -FA1 "$branch" | tail -n1 | sed 's/^\*//' | awk '{$1=$1};1')
        [[ "$parentBranch" != "$branch" ]] || parentBranch="$manifestRev"
    else
        parentBranch="$manifestRev"
    fi

    if ! git rev-parse --verify -q "$parentBranch" &> /dev/null; then
        showError "Missing parent branch: $parentBranch"
    fi
    echo "  Parent branch: $parentBranch"

    if git diff --quiet $parentBranch..$branch; then
        echo "  No differences to parent"
        continue
    fi
    name=$(repo info . | grep 'Project:' | cut -d ' ' -f2)
    name=${name#LineageOS/}
    name=${name//\//_}

    echo "# PWD: $dir" > "$targetDir/$name.patch"
    git diff -U5 $manifestRev..$branch >> "$targetDir/$name.patch"
    git format-patch --output-directory "$targetDir/$name" --quiet $parentBranch..$branch
done

echo "Files in $targetDir"
