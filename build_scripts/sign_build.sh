#!/bin/env bash

# Sign a LOS build after `mka target-files-package otatools-package`
# Call as: `sign_build.sh $(get_build_var PLATFORM_VERSION) $(get_build_var LINEAGE_VERSION)`

set -eu

# shellcheck disable=SC2016
PLATFORM_VERSION=${1:?'Error. You must supply $(get_build_var PLATFORM_VERSION).'}
# shellcheck disable=SC2016
LINEAGE_VERSION=${2:?'Error. You must supply $(get_build_var LINEAGE_VERSION).'}

keyDir=$ANDROID_BUILD_TOP/vendor/extra/keys
if [[ ! -d $keyDir ]]; then
    echo "Missing key dir $keyDir" && false
fi

targetFilesInputs=("$OUT/obj/PACKAGING/target_files_intermediates/$TARGET_PRODUCT-target_files-"*.zip)
if [[ ${#targetFilesInputs[@]} != 1 ]]; then
    echo "Failed to find input: ${targetFilesInputs[*]}" && false
fi
targetFilesInput=${targetFilesInputs[0]}
targetFilesSigned="$OUT/target-files-$LINEAGE_VERSION-signed.zip"
targetFileName="lineage-$LINEAGE_VERSION.zip"
targetFile="$OUT/$targetFileName"

if ((PLATFORM_VERSION < 12)); then
    sign_target_files_apks -o -d "$keyDir" \
        "$targetFilesInput" "$targetFilesSigned"
else
    sign_target_files_apks -o -d "$keyDir" \
        --extra_apks AdServicesApk.apk="$keyDir"/releasekey \
        --extra_apks FederatedCompute.apk="$keyDir"/releasekey \
        --extra_apks HalfSheetUX.apk="$keyDir"/releasekey \
        --extra_apks HealthConnectBackupRestore.apk="$keyDir"/releasekey \
        --extra_apks HealthConnectController.apk="$keyDir"/releasekey \
        --extra_apks OsuLogin.apk="$keyDir"/releasekey \
        --extra_apks SafetyCenterResources.apk="$keyDir"/releasekey \
        --extra_apks ServiceConnectivityResources.apk="$keyDir"/releasekey \
        --extra_apks ServiceUwbResources.apk="$keyDir"/releasekey \
        --extra_apks ServiceWifiResources.apk="$keyDir"/releasekey \
        --extra_apks WifiDialog.apk="$keyDir"/releasekey \
        --extra_apks com.android.adbd.apex="$keyDir"/com.android.adbd \
        --extra_apks com.android.adservices.apex="$keyDir"/com.android.adservices \
        --extra_apks com.android.adservices.api.apex="$keyDir"/com.android.adservices.api \
        --extra_apks com.android.appsearch.apex="$keyDir"/com.android.appsearch \
        --extra_apks com.android.appsearch.apk.apex="$keyDir"/com.android.appsearch.apk \
        --extra_apks com.android.art.apex="$keyDir"/com.android.art \
        --extra_apks com.android.bluetooth.apex="$keyDir"/com.android.bluetooth \
        --extra_apks com.android.btservices.apex="$keyDir"/com.android.btservices \
        --extra_apks com.android.cellbroadcast.apex="$keyDir"/com.android.cellbroadcast \
        --extra_apks com.android.compos.apex="$keyDir"/com.android.compos \
        --extra_apks com.android.configinfrastructure.apex="$keyDir"/com.android.configinfrastructure \
        --extra_apks com.android.connectivity.resources.apex="$keyDir"/com.android.connectivity.resources \
        --extra_apks com.android.conscrypt.apex="$keyDir"/com.android.conscrypt \
        --extra_apks com.android.devicelock.apex="$keyDir"/com.android.devicelock \
        --extra_apks com.android.extservices.apex="$keyDir"/com.android.extservices \
        --extra_apks com.android.graphics.pdf.apex="$keyDir"/com.android.graphics.pdf \
        --extra_apks com.android.hardware.authsecret.apex="$keyDir"/com.android.hardware.authsecret \
        --extra_apks com.android.hardware.biometrics.face.virtual.apex="$keyDir"/com.android.hardware.biometrics.face.virtual \
        --extra_apks com.android.hardware.biometrics.fingerprint.virtual.apex="$keyDir"/com.android.hardware.biometrics.fingerprint.virtual \
        --extra_apks com.android.hardware.boot.apex="$keyDir"/com.android.hardware.boot \
        --extra_apks com.android.hardware.cas.apex="$keyDir"/com.android.hardware.cas \
        --extra_apks com.android.hardware.neuralnetworks.apex="$keyDir"/com.android.hardware.neuralnetworks \
        --extra_apks com.android.hardware.rebootescrow.apex="$keyDir"/com.android.hardware.rebootescrow \
        --extra_apks com.android.hardware.wifi.apex="$keyDir"/com.android.hardware.wifi \
        --extra_apks com.android.healthfitness.apex="$keyDir"/com.android.healthfitness \
        --extra_apks com.android.hotspot2.osulogin.apex="$keyDir"/com.android.hotspot2.osulogin \
        --extra_apks com.android.i18n.apex="$keyDir"/com.android.i18n \
        --extra_apks com.android.ipsec.apex="$keyDir"/com.android.ipsec \
        --extra_apks com.android.media.apex="$keyDir"/com.android.media \
        --extra_apks com.android.media.swcodec.apex="$keyDir"/com.android.media.swcodec \
        --extra_apks com.android.mediaprovider.apex="$keyDir"/com.android.mediaprovider \
        --extra_apks com.android.nearby.halfsheet.apex="$keyDir"/com.android.nearby.halfsheet \
        --extra_apks com.android.networkstack.tethering.apex="$keyDir"/com.android.networkstack.tethering \
        --extra_apks com.android.neuralnetworks.apex="$keyDir"/com.android.neuralnetworks \
        --extra_apks com.android.nfcservices.apex="$keyDir"/com.android.nfcservices \
        --extra_apks com.android.ondevicepersonalization.apex="$keyDir"/com.android.ondevicepersonalization \
        --extra_apks com.android.os.statsd.apex="$keyDir"/com.android.os.statsd \
        --extra_apks com.android.permission.apex="$keyDir"/com.android.permission \
        --extra_apks com.android.profiling.apex="$keyDir"/com.android.profiling \
        --extra_apks com.android.resolv.apex="$keyDir"/com.android.resolv \
        --extra_apks com.android.rkpd.apex="$keyDir"/com.android.rkpd \
        --extra_apks com.android.runtime.apex="$keyDir"/com.android.runtime \
        --extra_apks com.android.safetycenter.resources.apex="$keyDir"/com.android.safetycenter.resources \
        --extra_apks com.android.scheduling.apex="$keyDir"/com.android.scheduling \
        --extra_apks com.android.sdkext.apex="$keyDir"/com.android.sdkext \
        --extra_apks com.android.support.apexer.apex="$keyDir"/com.android.support.apexer \
        --extra_apks com.android.telephony.apex="$keyDir"/com.android.telephony \
        --extra_apks com.android.telephonymodules.apex="$keyDir"/com.android.telephonymodules \
        --extra_apks com.android.tethering.apex="$keyDir"/com.android.tethering \
        --extra_apks com.android.tzdata.apex="$keyDir"/com.android.tzdata \
        --extra_apks com.android.uwb.apex="$keyDir"/com.android.uwb \
        --extra_apks com.android.uwb.resources.apex="$keyDir"/com.android.uwb.resources \
        --extra_apks com.android.virt.apex="$keyDir"/com.android.virt \
        --extra_apks com.android.vndk.current.apex="$keyDir"/com.android.vndk.current \
        --extra_apks com.android.vndk.current.on_vendor.apex="$keyDir"/com.android.vndk.current.on_vendor \
        --extra_apks com.android.wifi.apex="$keyDir"/com.android.wifi \
        --extra_apks com.android.wifi.dialog.apex="$keyDir"/com.android.wifi.dialog \
        --extra_apks com.android.wifi.resources.apex="$keyDir"/com.android.wifi.resources \
        --extra_apks com.google.pixel.camera.hal.apex="$keyDir"/com.google.pixel.camera.hal \
        --extra_apks com.google.pixel.vibrator.hal.apex="$keyDir"/com.google.pixel.vibrator.hal \
        --extra_apks com.qorvo.uwb.apex="$keyDir"/com.qorvo.uwb \
        --extra_apex_payload_key com.android.adbd.apex="$keyDir"/com.android.adbd.pem \
        --extra_apex_payload_key com.android.adservices.apex="$keyDir"/com.android.adservices.pem \
        --extra_apex_payload_key com.android.adservices.api.apex="$keyDir"/com.android.adservices.api.pem \
        --extra_apex_payload_key com.android.appsearch.apex="$keyDir"/com.android.appsearch.pem \
        --extra_apex_payload_key com.android.appsearch.apk.apex="$keyDir"/com.android.appsearch.apk.pem \
        --extra_apex_payload_key com.android.art.apex="$keyDir"/com.android.art.pem \
        --extra_apex_payload_key com.android.bluetooth.apex="$keyDir"/com.android.bluetooth.pem \
        --extra_apex_payload_key com.android.btservices.apex="$keyDir"/com.android.btservices.pem \
        --extra_apex_payload_key com.android.cellbroadcast.apex="$keyDir"/com.android.cellbroadcast.pem \
        --extra_apex_payload_key com.android.compos.apex="$keyDir"/com.android.compos.pem \
        --extra_apex_payload_key com.android.configinfrastructure.apex="$keyDir"/com.android.configinfrastructure.pem \
        --extra_apex_payload_key com.android.connectivity.resources.apex="$keyDir"/com.android.connectivity.resources.pem \
        --extra_apex_payload_key com.android.conscrypt.apex="$keyDir"/com.android.conscrypt.pem \
        --extra_apex_payload_key com.android.devicelock.apex="$keyDir"/com.android.devicelock.pem \
        --extra_apex_payload_key com.android.extservices.apex="$keyDir"/com.android.extservices.pem \
        --extra_apex_payload_key com.android.graphics.pdf.apex="$keyDir"/com.android.graphics.pdf.pem \
        --extra_apex_payload_key com.android.hardware.authsecret.apex="$keyDir"/com.android.hardware.authsecret.pem \
        --extra_apex_payload_key com.android.hardware.biometrics.face.virtual.apex="$keyDir"/com.android.hardware.biometrics.face.virtual.pem \
        --extra_apex_payload_key com.android.hardware.biometrics.fingerprint.virtual.apex="$keyDir"/com.android.hardware.biometrics.fingerprint.virtual.pem \
        --extra_apex_payload_key com.android.hardware.boot.apex="$keyDir"/com.android.hardware.boot.pem \
        --extra_apex_payload_key com.android.hardware.cas.apex="$keyDir"/com.android.hardware.cas.pem \
        --extra_apex_payload_key com.android.hardware.neuralnetworks.apex="$keyDir"/com.android.hardware.neuralnetworks.pem \
        --extra_apex_payload_key com.android.hardware.rebootescrow.apex="$keyDir"/com.android.hardware.rebootescrow.pem \
        --extra_apex_payload_key com.android.hardware.wifi.apex="$keyDir"/com.android.hardware.wifi.pem \
        --extra_apex_payload_key com.android.healthfitness.apex="$keyDir"/com.android.healthfitness.pem \
        --extra_apex_payload_key com.android.hotspot2.osulogin.apex="$keyDir"/com.android.hotspot2.osulogin.pem \
        --extra_apex_payload_key com.android.i18n.apex="$keyDir"/com.android.i18n.pem \
        --extra_apex_payload_key com.android.ipsec.apex="$keyDir"/com.android.ipsec.pem \
        --extra_apex_payload_key com.android.media.apex="$keyDir"/com.android.media.pem \
        --extra_apex_payload_key com.android.media.swcodec.apex="$keyDir"/com.android.media.swcodec.pem \
        --extra_apex_payload_key com.android.mediaprovider.apex="$keyDir"/com.android.mediaprovider.pem \
        --extra_apex_payload_key com.android.nearby.halfsheet.apex="$keyDir"/com.android.nearby.halfsheet.pem \
        --extra_apex_payload_key com.android.networkstack.tethering.apex="$keyDir"/com.android.networkstack.tethering.pem \
        --extra_apex_payload_key com.android.neuralnetworks.apex="$keyDir"/com.android.neuralnetworks.pem \
        --extra_apex_payload_key com.android.nfcservices.apex="$keyDir"/com.android.nfcservices.pem \
        --extra_apex_payload_key com.android.ondevicepersonalization.apex="$keyDir"/com.android.ondevicepersonalization.pem \
        --extra_apex_payload_key com.android.os.statsd.apex="$keyDir"/com.android.os.statsd.pem \
        --extra_apex_payload_key com.android.permission.apex="$keyDir"/com.android.permission.pem \
        --extra_apex_payload_key com.android.profiling.apex="$keyDir"/com.android.profiling.pem \
        --extra_apex_payload_key com.android.resolv.apex="$keyDir"/com.android.resolv.pem \
        --extra_apex_payload_key com.android.rkpd.apex="$keyDir"/com.android.rkpd.pem \
        --extra_apex_payload_key com.android.runtime.apex="$keyDir"/com.android.runtime.pem \
        --extra_apex_payload_key com.android.safetycenter.resources.apex="$keyDir"/com.android.safetycenter.resources.pem \
        --extra_apex_payload_key com.android.scheduling.apex="$keyDir"/com.android.scheduling.pem \
        --extra_apex_payload_key com.android.sdkext.apex="$keyDir"/com.android.sdkext.pem \
        --extra_apex_payload_key com.android.support.apexer.apex="$keyDir"/com.android.support.apexer.pem \
        --extra_apex_payload_key com.android.telephony.apex="$keyDir"/com.android.telephony.pem \
        --extra_apex_payload_key com.android.telephonymodules.apex="$keyDir"/com.android.telephonymodules.pem \
        --extra_apex_payload_key com.android.tethering.apex="$keyDir"/com.android.tethering.pem \
        --extra_apex_payload_key com.android.tzdata.apex="$keyDir"/com.android.tzdata.pem \
        --extra_apex_payload_key com.android.uwb.apex="$keyDir"/com.android.uwb.pem \
        --extra_apex_payload_key com.android.uwb.resources.apex="$keyDir"/com.android.uwb.resources.pem \
        --extra_apex_payload_key com.android.virt.apex="$keyDir"/com.android.virt.pem \
        --extra_apex_payload_key com.android.vndk.current.apex="$keyDir"/com.android.vndk.current.pem \
        --extra_apex_payload_key com.android.vndk.current.on_vendor.apex="$keyDir"/com.android.vndk.current.on_vendor.pem \
        --extra_apex_payload_key com.android.wifi.apex="$keyDir"/com.android.wifi.pem \
        --extra_apex_payload_key com.android.wifi.dialog.apex="$keyDir"/com.android.wifi.dialog.pem \
        --extra_apex_payload_key com.android.wifi.resources.apex="$keyDir"/com.android.wifi.resources.pem \
        --extra_apex_payload_key com.google.pixel.camera.hal.apex="$keyDir"/com.google.pixel.camera.hal.pem \
        --extra_apex_payload_key com.google.pixel.vibrator.hal.apex="$keyDir"/com.google.pixel.vibrator.hal.pem \
        --extra_apex_payload_key com.qorvo.uwb.apex="$keyDir"/com.qorvo.uwb.pem \
        "$targetFilesInput" "$targetFilesSigned"
fi

ota_from_target_files -k "$keyDir"/releasekey \
    --block --backup=true \
    "$targetFilesSigned" "$targetFile"

echo "Created $targetFile"
