# English patch for Umineko Catbox

This is an English patch for Umineko When They Cry: The Symphony of Catbox and Dreams, the console version
of Umineko on Nintendo Switch.

This patch is meant to be used on the **actual console release of the game**. It is ***not* a standalone application**.

## Credits

Besides me, the following people have *directly* contributed to this project:
- [@DoctorDiablo](//github.com/doctordiablo), translating the Witch Hunter's Interview Tape story.
- [@silverwolf-waltz](//github.com/silverwolf-waltz), porting over the translation for Last Note.
- [@Quplet](//github.com/quplet), providing help with porting some of the main episodes.
- [LHCollider](https://www.youtube.com/lhcollider) and OphidianLass, helping with testing.

Furthermore, this patch would be impossible without the resources and tools provided by the the following projects:

- [kaleido](https://gitlab.com/Neurochitin/kaleido/-/tree/saku/) by Neurochitin, which can decompile and recompile the SNR script format used by the game, as well as generate the `patch.rom` files that can be used to replace files in the base game.
- [enter_extractor](https://github.com/07th-mod/enter_extractor) by TellowKrinkle, which can extract files from the base game's `data.rom` format, as well as generate `pic` and `txa` files used to store the game's images.
- [HigurashiENX](https://github.com/masagrator/HigurashiENX) by MasaGratoR, which is a similar translation patch for the Switch version of Higurashi. Specifically, the IPS patch generation scripts from that project were used to translate some of the text hardcoded into the executables of the game.
- [Umineko Project](https://umineko-project.org), a similar translation work done for the PS3 version of Umineko, which serves as the base for the translated script and images used in the patch.
- [Umineko Tsubasa English Patch](https://uminekotsubasa.github.io/), which served as the intiial source for the translation of the Tsubasa arcs present in the PC version (these were *heavily* edited to be consistent with the main story as well as with each other).
- ArsMagica's English patch for Hane, now lost to time, which served as the initial source for the translation of the Hane arcs.
- The 07th-Expansion wiki, which had a translation for Our Confession as well as most of the new Tsubasa stories.
- A person called "last-note" who just showed up on the Hinamizawa Discord one day, dumped a full translation of Last Note, and left.
- The original translation of the PC version of Umineko by [The Witch Hunt](https://witch-hunt.com). While their work isn't being used directly, without these people Umineko would have never made it to the West in any form at all.
- And, of course, the game itself, created by 07th-Expansion and producted (sic) by Entergram. Please buy the game on the [eShop](https://store-jp.nintendo.com/list/software/70010000012343.html) to support the creators.
  - You can *technically* also buy the game on [PSN](https://store.playstation.com/ja-jp/product/JP0741-CUSA16973_00-UMINEKOSAKUZZZZZ), though that version isn't fully compatible with the patch, and the parts that *may be* compatible (romfs changes) are untested. If you get that one, you're on your own in trying to get it to run.
  - There are also a few various versions of Umineko native to PC. How good they are varies depending on the version you dig up, but none of them properly support the creators, none of them are compatible with this patch, and all of them have various missing content compared to the console release of the game.
    - This includes the Steam version, as it is a re-release of the old indie version of Umineko, and as such does not include any of the console version's improvements. Because of this, buying this release does not help support the creators of the console version in any way, though it *does* help support the author and the original creator of the series, Ryukishi07. The Steam version is also not compatible with this patch.

## Applying the patch

The game, and this patch, can be played either on PC, via a Switch emulator
(both Ryujinx and Yuzu have been tested with the patch and both work perfectly, so choose whichever you prefer)
or on a hackable Nintendo Switch, via Atmosphère. Please follow the below instructions to get the patch set up.

Note that to play on PC, you will need to acquire an NSP of the base game and add it to your emulator.

To comply with US laws, you have to buy the game on the [eShop](https://store-jp.nintendo.com/list/software/70010000012343.html) and dump it using [nxdumptool](https://github.com/DarkMatterCore/nxdumptool) from a hackable Nintendo Switch to obtain a legal copy for emulation. Software distribution laws in other countries may vary.

### On PC (via Ryujinx)

The Switch emulator [Ryujinx](https://ryujinx.org/) is compatible with the game and the patch.

To set Ryujinx up, you will need a copy of the `prod.keys` file dumped from a hackable Nintendo Switch, the Nintendo Switch firmware, and the game itself. Having acquired these, you may [follow their guide](https://github.com/Ryujinx/Ryujinx/wiki/Ryujinx-Setup-&-Configuration-Guide) to finish your configuration and add the game to the emulator, but please ignore the "Managing mods" section as this patch has a somewhat more complicated structure and cannot be simply added to a per-game folder like they recommend.

To install the patch, [download](../../releases/latest/download/patch_atmos.zip) the Atmosphère version (Ryujinx is 100% Atmosphère-compatible),
<br>then choose File -> Open Ryujinx Folder. Navigate to the "mods" directory and extract the entire archive to that location. If the "mods" directory does not exist, create it first.

### On PC (via Yuzu)
Another Switch emulator, [Yuzu](https://yuzu-emu.org), is also compatible with the game and the patch.

To set Yuzu up, you will need a copy of the `prod.keys` file dumped from a hackable Nintendo Switch and the game itself. Once you have acquired the keys, navigate to File -> Open Yuzu folder, then find (or create) the subfolder called "keys" inside that and paste the file there. Restart Yuzu and double-click the giant empty rectangle in the main yuzu window to add your game folder.

To install the patch, [download](../../releases/latest/download/patch_yuzu.zip) the Yuzu version,
<br>then right-click the game in Yuzu, choose "Open Mod Data Location" and extract the entire archive there.

### On Nintendo Switch (the actual hardware)

If you want to play the game on your Nintendo Switch hardware, it will need [Atmosphère](https://github.com/Atmosphere-NX/Atmosphere) installed on it.
If you don't have Atmosphère already, please see if it's compatible with your Switch model and install it if it is.
Afterwards, [download](../../releases/latest/download/patch_atmos.zip) the Atmosphère version of the patch and copy it to the "atmosphere" folder on your SD card.
The next time the game starts, it should be in English.

## More questions?

Use the [forums](../../discussions) to ask them and I'll try to answer as soon as I'm able to. If (and *only* if) you find a bug, please open an [issue](../../issues) instead.

## Developer documentation

Some limited docs for those who wish to contribute to patch development, or perhaps translate the script into another language, are available [here](CONTRIBUTING.md).
