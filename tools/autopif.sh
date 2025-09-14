#!/usr/bin/env bash

# pif.json extractor script by osm0sis @ xda-developers
# Modified by Flamefire

set -euo pipefail

function error {
  echo "$@"
  exit 1
}

function download {
  url=$1
  file=${2:-}
  echo "- Downloading $url ..." >&2;
  if [[ -n "$file" ]]; then
    curl --silent --show-error --location --output "${file}" "${url}" || error "Failed"
  else
    curl --silent --show-error --location "${url}" || error "Failed"
  fi
}

if (( $# == 0 )); then
    cd "$(dirname "$0")"
else
    { mkdir -p "$1" && cd "$1"; } || error "Failed to change to specified folder $1"
fi

# Get latest Pixel Beta information
download https://developer.android.com/about/versions PIXEL_VERSIONS_HTML
BETA_URL=$(grep -o 'https://developer.android.com/about/versions/.*[0-9]"' PIXEL_VERSIONS_HTML | sort -ru | cut -d\" -f1 | head -n1)
download "$BETA_URL" PIXEL_LATEST_HTML

# Get OTA information
OTA_URL="https://developer.android.com$(grep -o 'href=".*download-ota.*"' PIXEL_LATEST_HTML | grep 'qpr' | cut -d\" -f2 | head -n1)"
download "$OTA_URL" PIXEL_OTA_HTML

# Extract device information
MODEL_LIST=$(grep -A1 'tr id=' PIXEL_OTA_HTML | grep 'td' | sed 's;.*<td>\(.*\)</td>;\1;')
PRODUCT_LIST=$(grep -o 'tr id="[^"]*"' PIXEL_OTA_HTML | awk -F\" '{print $2 "_beta"}')
OTA_LIST=$(grep 'ota/.*_beta' PIXEL_OTA_HTML | cut -d\" -f2)

# Select and configure device
echo "- Selecting Pixel Beta device ..."
count=$(echo "$MODEL_LIST" | wc -l)
count2=$(echo "$PRODUCT_LIST" | wc -l)
if ((count != count2)); then
  echo "Warning: MODEL_LIST and PRODUCT_LIST have different lengths, using Pixel 6 fallback"
  MODEL="Pixel 6"
  PRODUCT="oriole_beta"
  OTA_LINK_CHECK="$(echo "$OTA_LIST" | grep "$PRODUCT")"
else
  rand_index=$(( $$ % count + 1 ))
  MODEL=$(echo "$MODEL_LIST" | sed -n "${rand_index}p")
  PRODUCT=$(echo "$PRODUCT_LIST" | sed -n "${rand_index}p")
  OTA_LINK_CHECK=$(echo "$OTA_LIST" | sed -n "${rand_index}p")
fi
echo "$MODEL ($PRODUCT)"

# Get device fingerprint and security patch from OTA metadata
OTA_LINK="$(echo "$OTA_LIST" | grep "$PRODUCT")"
[[ "$OTA_LINK" == "$OTA_LINK_CHECK" ]] || echo "WARNING: Different links: '$OTA_LINK' != '$OTA_LINK_CHECK'"
set +o pipefail
download "$OTA_LINK" | grep -ao '[ -~]\{10,\}' | head -n15 > PIXEL_ZIP_METADATA
set -o pipefail
FINGERPRINT="$(grep -am1 'post-build=' PIXEL_ZIP_METADATA | cut -d= -f2)"
SECURITY_PATCH="$(grep -am1 'security-patch-level=' PIXEL_ZIP_METADATA | cut -d= -f2)"

[[ -n "$FINGERPRINT" ]] && [[ -n "$SECURITY_PATCH" ]] || error "Failed to get meta data from OTA"

echo "- Writing pif.json..."
echo ""
cat <<EOF | tee pif.json
{
  "FIRST_API_LEVEL": "25",
  "RELEASE": "",
  "MANUFACTURER": "Google",
  "PRODUCT": "$PRODUCT",
  "MODEL": "$MODEL",
  "FINGERPRINT": "$FINGERPRINT",
  "SECURITY_PATCH": "$SECURITY_PATCH"
}
EOF
