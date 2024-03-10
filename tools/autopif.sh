#!/usr/bin/env bash

echo -e "Xiaomi.eu pif.json extractor script \
  \n  by osm0sis @ xda-developers";

case "$0" in
  *.sh) DIR="$0";;
  *) DIR="$(lsof -p $$ 2>/dev/null | grep -o '/.*autopif.sh$')";;
esac;
DIR=$(dirname "$(readlink -f "$DIR")");

cd "$DIR";

if ! which wget >/dev/null; then
    echo "autopif: wget not found";
    exit 1;
fi;

echo -e "\n- Finding latest APK from RSS feed ...";
APKURL=$(wget -q -O - --no-check-certificate https://sourceforge.net/projects/xiaomi-eu-multilang-miui-roms/rss?path=/xiaomi.eu/Xiaomi.eu-app | grep -o '<link>.*' | head -n 2 | tail -n 1 | sed 's;<link>\(.*\)</link>;\1;g');
APKNAME=$(echo $APKURL | sed 's;.*/\(.*\)/download;\1;g');
echo "$APKNAME";

if [ ! -f $APKNAME ]; then
  echo "\n- Downloading $APKNAME ...";
  wget -q --no-check-certificate -O $APKNAME $APKURL || exit 1;
fi;

OUT=$(basename $APKNAME .apk);
if [ ! -d $OUT ]; then
  echo "\n- Extracting APK files with Apktool ...";
  apktool d -f --no-src -p $OUT -o $OUT $APKNAME || exit 1;
fi;

echo -e "\n- Converting inject_fields.xml to pif.json ...";
(echo '{';
grep -o '<field.*' $OUT/res/xml/inject_fields.xml | sed 's;.*name=\(".*"\) type.* value=\(".*"\).*;  \1: \2,;g';
echo '  "FIRST_API_LEVEL": "25",' ) | sed '$s/,/\n}/' | tee pif.json;
