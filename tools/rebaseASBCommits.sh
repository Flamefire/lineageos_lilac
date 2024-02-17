#!/bin/env bash
set -euo pipefail

old_branch="${1:-}"

for branch in $(git branch --list --format='%(refname:short)' --sort=refname 'asb-*'); do
    if [[ -n $old_branch ]]; then
        git checkout $branch
        git rebase $old_branch
    fi
    old_branch=$branch
done
