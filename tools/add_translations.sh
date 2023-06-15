#!/usr/bin/bash

set -eu

name=${1:?Missing translation name entry}
target=${2:?Missing target}

pattern='(name="[^"]+")'

while read -r match; do
    file=${match%:*}
    line=${match##*:}
    replaceLine=$line
    [[ $replaceLine != " "* ]] || replaceLine='\\'$replaceLine

    newFile=$target/$file
    [[ -f $newFile ]] || { echo "Skipping non-existing $newFile"; continue; }

    prior=$(grep -F --before-context=1 "$line" "$file" | head -n1)
    [[ "$prior" =~ $pattern ]] || { echo "Missing name in $file: $prior"; exit 1; }
    posName=${BASH_REMATCH[1]}
    if grep -qF "$posName" "$newFile"; then
        sed -i "\|$posName|a $replaceLine" "$newFile"
        continue
    fi

    after=$(grep -F --after-context=1 "$line" "$file" | tail -n1)
    [[ "$after" =~ $pattern ]] || { echo "Missing after name in $file: $after"; exit 1; }
    posName=${BASH_REMATCH[1]}
    grep -qF "$posName" "$newFile" || posName="</resources>"
    sed -i "\|$posName|i $replaceLine" "$newFile"
    
done < <(grep -rF "$name" res/values-*)
