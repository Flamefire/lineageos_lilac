#!/usr/bin/env bash

set -euo pipefail

function showError {
    echo -e "\033[0;31mERROR: $@\033[0m" && false
}

[[ -L .git ]] || showError "Not in a repo git repository"

repo_dir=$PWD
while [[ -n "$repo_dir" && ! -d "$repo_dir/.repo" ]]; do
    repo_dir=$(dirname "$repo_dir")
done
[[ -n "$repo_dir" ]] || showError "Didn't find repo dir in parents of $PWD"
echo "Repo dir: $repo_dir"
repo_objects_dir="$repo_dir/.repo/project-objects"
[[ -d "$repo_objects_dir" ]] || showError "Didn't find repo objects dir at $repo_objects_dir"

[[ $(readlink -f ".git") == "$repo_dir/.repo"* ]] || showError "Invalid .git link"

[[ -L .git/objects ]] || showError ".git/objects is not a link"
objects_dir=$(dirname "$(readlink -f ".git/objects")")
[[ "$objects_dir" == "$repo_objects_dir/"* ]] || showError "Invalid .git/objects link"
[[ "$objects_dir" == *".git" ]] || showError "Objects dir name invalid: $objects_dir"
[[ -d "$objects_dir" ]] || showError "Objects dir not found: $objects_dir"

sub_object_dir=${objects_dir#$repo_objects_dir/}
[[ "$sub_object_dir" != "LineageOS/android_"* ]] || showError "Already tracking the LOS objects: $sub_object_dir"
[[ "$sub_object_dir" =~ ^platform/ ]] || showError "Unexpected object dir name (should be subfolder of 'platform'): $sub_object_dir"
sub_object_dir_base=${sub_object_dir#platform/}
sub_object_dir_new=LineageOS/android_${sub_object_dir_base//\//_}
echo "$sub_object_dir -> $sub_object_dir_new"

links=($(find .git/ -type l))

for l in "${links[@]}"; do
    target=$(readlink "$l")
    new_target=${target/$sub_object_dir/$sub_object_dir_new}
    [[ -n "$target" && -n "$new_target" && "$target" != "$new_target" ]] || showError "Can't transform link $l:$target"
done

## Actual modifications

set -x
mv "$repo_objects_dir/$sub_object_dir" "$repo_objects_dir/$sub_object_dir_new"
{ set +x; } 2>/dev/null

for l in "${links[@]}"; do
    target=$(readlink "$l")
    new_target=${target/$sub_object_dir/$sub_object_dir_new}
    set -x
    ln -fns "$new_target" "$l"
    { set +x; } 2>/dev/null
done

