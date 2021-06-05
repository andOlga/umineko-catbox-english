#!/bin/bash
set -e
cd repack/rom-repack
ruby kal_real.rb ../../script.rb ../../romfs ../../patch.rom ../../patch.snr 6 19 88
cd ../..
python3 build_bgame.py
MODBASE=mods/contents/01006a300ba2c000/english/
mkdir -p $MODBASE/romfs/
mv patch.rom $MODBASE/romfs/patch.rom
cp -r exefs $MODBASE/exefs
mkdir -p mods/exefs_patches/umineko/
mv *.ips mods/exefs_patches/umineko/
zip -r patch.zip mods
rm -r mods patch.snr
# This is a script I use to copy the mod to my emulator right away, it's not in the repo
if [ -e 'update_local_mod.sh' ] ; then bash update_local_mod.sh ; fi
