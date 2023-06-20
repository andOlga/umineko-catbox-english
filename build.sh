#!/bin/sh
# Build requirements: Python 3, Ruby, zip
set -e

if [ -e "font_manifests" ]
then
    echo "=== Copying font manifests... ==="
    cp font_manifests/regular repack/rom-repack/font/regular
    cp font_manifests/bold repack/rom-repack/font/bold
fi

echo "=== Building romfs... ==="
cd repack/rom-repack
ruby kal_real.rb ../../script.rb ../../romfs ../../patch.rom ../../patch.snr 6 19 88
cd ../..

echo "=== Building exefs... ==="
python3 build_exefs_text.py

echo "=== Generating mod directory structure... ==="
MODBASE=mods/contents/01006a300ba2c000/
mkdir -p $MODBASE/romfs/
mv patch.rom $MODBASE/romfs/patch.rom
cp -r exefs $MODBASE/exefs
mkdir -p mods/exefs_patches/umineko/
mv 7616F8963DACCD70E20FF3904E13367F96F2D9B3000000000000000000000000.ips mods/exefs_patches/umineko/
rm patch.snr

echo "=== Deploying... ==="
if [ -e "$UMINEKO_TARGET" ]
then # Local/dev build
    cp -rf mods "$UMINEKO_TARGET"
    rm -rf mods
elif [ -e "$UMINEKO_TARGET_YUZU" ]
then # Local/dev build
    MODBASE_YUZU=$UMINEKO_TARGET_YUZU/load/01006A300BA2C000/UminekoCatboxEnglish
    mkdir -p "$MODBASE_YUZU/" 2> /dev/null || true
    cp -rf $MODBASE/* "$MODBASE_YUZU/"
    cp -rf mods/exefs_patches/umineko/*.ips "$MODBASE_YUZU/exefs/"
    rm -rf mods
else # Public build
    cd mods
    if [ "$SKIP_ARCHIVE" != "1" ]
    then
        zip -r ../patch_atmos.zip .
    fi
    cd ..
    mkdir UminekoCatboxEnglish
    cp -r $MODBASE/* UminekoCatboxEnglish/
    cp mods/exefs_patches/umineko/*.ips UminekoCatboxEnglish/exefs/
    if [ "$SKIP_ARCHIVE" != 1 ]
    then
        zip -r patch_yuzu.zip UminekoCatboxEnglish
    fi
    cd ..
fi
