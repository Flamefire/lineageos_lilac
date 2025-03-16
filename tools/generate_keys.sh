#!/bin/env bash

# Generate keys for building and signing Android images
# Key files are NOT password protected!

set -eu

keyDir=${1:?"Error. You must supply a key directory."}
#E.g. subject='/C=US/ST=California/L=Mountain View/O=Android/OU=Android/CN=Android/emailAddress=android@android.com'
subject=${2:?"Error. You must supply a subject for keys."}

mkdir -p "$keyDir"
make_key=$(mktemp)
cp development/tools/make_key "$make_key"
chmod +x "$make_key"
sed -i 's|2048|4096|g' "$make_key"
sed -i "s|exit 1' EXIT|exit 0' EXIT|g" "$make_key"


for cert in bluetooth cyngn-app media networkstack nfc platform releasekey sdk_sandbox shared testcert testkey verity; do
    cert=$keyDir/$cert
    [[ ! -f "${cert}.pk8" ]] || continue
    echo "" | "$make_key" "$cert" "$subject"
done
for apex in com.android.adbd com.android.adservices com.android.adservices.api com.android.appsearch com.android.appsearch.apk com.android.art com.android.bluetooth com.android.btservices com.android.cellbroadcast com.android.compos com.android.configinfrastructure com.android.connectivity.resources com.android.conscrypt com.android.devicelock com.android.extservices com.android.graphics.pdf com.android.hardware.authsecret com.android.hardware.biometrics.face.virtual com.android.hardware.biometrics.fingerprint.virtual com.android.hardware.boot com.android.hardware.cas com.android.hardware.neuralnetworks com.android.hardware.rebootescrow com.android.hardware.wifi com.android.healthfitness com.android.hotspot2.osulogin com.android.i18n com.android.ipsec com.android.media com.android.media.swcodec com.android.mediaprovider com.android.nearby.halfsheet com.android.networkstack.tethering com.android.neuralnetworks com.android.nfcservices com.android.ondevicepersonalization com.android.os.statsd com.android.permission com.android.profiling com.android.resolv com.android.rkpd com.android.runtime com.android.safetycenter.resources com.android.scheduling com.android.sdkext com.android.support.apexer com.android.telephony com.android.telephonymodules com.android.tethering com.android.tzdata com.android.uwb com.android.uwb.resources com.android.virt com.android.vndk.current com.android.vndk.current.on_vendor com.android.wifi com.android.wifi.dialog com.android.wifi.resources com.google.pixel.camera.hal com.google.pixel.vibrator.hal com.qorvo.uwb; do
    apexSubject=$(echo "$subject" | sed -E "s|/CN=.*?/|/CN=$apex/|")
    cert="$keyDir/$apex"
    if [[ ! -f "${cert}.pk8" ]]; then
        echo "" | "$make_key" "$cert" "$apexSubject"
    fi
    if [[ ! -f "${cert}.pem" ]]; then
        openssl pkcs8 -in "$cert".pk8 -inform DER -nocrypt -out "$cert".pem
    fi
done
