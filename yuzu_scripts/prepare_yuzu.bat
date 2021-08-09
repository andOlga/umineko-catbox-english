cd /d %~dp0
mkdir yuzu_mod
xcopy mods\contents\01006a300ba2c000\exefs yuzu_mod\exefs\
xcopy mods\contents\01006a300ba2c000\romfs yuzu_mod\romfs\
copy mods\exefs_patches\umineko\*.ips yuzu_mod\exefs\