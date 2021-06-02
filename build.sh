#!/bin/bash
cd repack/rom-repack
ruby kal_real.rb ../../script.rb ../../romfs ../../patch.rom ../../patch.snr 6 19 88
cd ../..
mkdir -p english/romfs/
mv patch.rom english/romfs/patch.rom
cp -r exefs english/exefs
zip -r patch.zip english
rm -r english patch.snr
# This is a script I use to copy the mod to my emulator right away, it's not in the repo
[ -e 'update_local_mod.sh' ] && bash update_local_mod.sh
