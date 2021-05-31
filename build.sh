#!/bin/bash
cd repack/rom-repack
ruby kal_real.rb ../../script.rb ../../romfs ../../patch.rom ../../patch.snr 6 19 88
cd ../..
mkdir -p english/romfs/
mv patch.rom english/romfs/patch.rom
cp -r exefs english/exefs
zip -r patch.zip english
rm -r english patch.snr
