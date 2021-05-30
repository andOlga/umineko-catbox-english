#!/bin/bash
rm patch.rom
cd repack/rom-repack
ruby kal_real.rb ../../script.rb ../../ass ../../patch.rom ../../patch.snr 6 19 88
cd ../..
mkdir -p english/romfs/
mv patch.rom english/romfs/patch.rom
zip -r patch.zip english
rm patch.snr english -r
