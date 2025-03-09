#!/usr/bin/env bash

# Xiaomi.eu pif.json extractor script by osm0sis @ xda-developers
# Modified by Flamefire

set -euo pipefail

function error {
  echo "$@"
  exit 1
}

if (( $# == 0 )); then
    cd "$(dirname "$0")"
else
    { mkdir -p "$1" && cd "$1"; } || error "Failed to change to specified folder $1"
fi

echo "- Finding latest APK from RSS feed ...";
url="https://sourceforge.net/projects/xiaomi-eu-multilang-miui-roms/rss?path=/xiaomi.eu/Xiaomi.eu-app"
APKURL=$(curl --silent --show-error "$url" | grep -o '<link>.*' | head -n 2 | tail -n 1 | sed 's;<link>\(.*\)</link>;\1;g') || error "Failed"

APKNAME="xiaomi.apk"

echo "- Downloading $url ...";
curl --silent --show-error --location --output "${APKNAME}" "${APKURL}" || error "Failed"

OUT=$(basename $APKNAME .apk);
echo "- Extracting APK files with Apktool ...";
apktool d -f --no-src -p "$OUT" -o "$OUT" "$APKNAME" || error "Failed"

echo "- Converting inject_fields.xml to pif.json ..."
(
  echo '{'
  echo '  "FIRST_API_LEVEL": "25",'
  echo '  "RELEASE": "12",'
  grep -o '<field.*' "$OUT/res/xml/inject_fields.xml" | sed 's;.*name=\(".*"\) type.* value=\(".*"\).*;  \1: \2,;g'
) | sed '$s/,/\n}/' | tee pif.json

rm -r "$OUT" "$APKNAME" || error "Failed to delete temporaries"
