#!/bin/bash
# Build requirements: Python 3 with Numpy, Ruby, zip
set -e

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
else # Public/Github build
    cd mods
    zip -r ../patch_atmos.zip .
    cd ..
    mkdir yuzu_mod
    cp -r $MODBASE/* yuzu_mod/
    cp mods/exefs_patches/umineko/*.ips yuzu_mod/exefs/
    cd yuzu_mod
    zip -r ../patch_yuzu.zip .
    cd ..
fi
