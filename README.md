# English patch for Umineko Catbox (UCE)

[![Patch build](https://github.com/ooa113y/umineko-catbox-english/actions/workflows/main.yml/badge.svg)](https://github.com/ooa113y/umineko-catbox-english/actions/workflows/main.yml)

## Project description
This is an English patch for Umineko When They Cry: The Symphony of Catbox and Dreams, the console version
of Umineko on Nintendo Switch and Sony PlayStation 4/5.

This patch is meant to be used on the **actual console releases of the game**. It is ***not* a standalone application**.

## Credits

This patch would be impossible without the assistance of the following projects:

- [kaleido](https://gitlab.com/Neurochitin/kaleido/-/tree/saku/) by Neurochitin, which can decompile and recompile the SNR script format used by the game, as well as generate the `patch.rom` files that can be used to replace files in the base game.
- [enter_extractor](https://github.com/07th-mod/enter_extractor) by TellowKrinkle, which can extract files from the base game's `data.rom` format, as well as generate `pic` and `txa` files used to store the game's images.
- [HigurashiENX](https://github.com/masagrator/HigurashiENX) by MasaGratoR, which is a similar translation patch for the Switch version of Higurashi. Specifically, the IPS patch generation scripts from that project were used to translate some of the text hardcoded into the executables of the game.
- [Umineko Project](https://umineko-project.org), a similar translation work done for the PS3 version of Umineko, which serves as the base for the translated script and images used in the patch.
- The original translation of the PC version of Umineko by [The Witch Hunt](https://witch-hunt.com). While their work isn't being used directly, without these people Umineko would have never made it to the West in any form at all.
- And, of course, the game itself, created by 07th-Expansion and producted (sic) by Entergram. Please buy the game on the [eShop](https://store-jp.nintendo.com/list/software/70010000012343.html) or [PSN](https://store.playstation.com/ja-jp/product/JP0741-CUSA16973_00-UMINEKOSAKUZZZZZ) to support the creators.
  - Please note that while you are welcome to buy the Steam release of Umineko to offer the authors additional support, it is not compatible with this patch. That version, while in English, is significantly inferior to the console releases (no voice acting, worse visuals, worse UI, missing content). Alternative PC ports of Umineko also exist, but none of them have full content coverage.

## Progress
The final goal of the patch is to translate the entire game into English, including all of the new content.
However, it is currently a work in progress, and it will take quite a bit of time until that goal is reached.

Currently, the "main" content (stuff that was present in all previous releases of Umineko,
i.e. Episodes 1-8) has been translated, however, only EPs 1-2 have been thoroughly tested so far.

Your experience with the untested episodes may range from encountering a couple of untranslated sentences here and there to outright crashes. Of course, I am working on testing and fixing the remaining episodes.

Bonus content (Tsubasa, Hane and the new Saku-exclusive stories) has not been touched at all yet. For now, it is fully in Japanese. I will get around to it when the main EPs are done.

A more detailed list of items that are being worked on can be found [here](../../issues/3).

## Applying the patch

### On PC (via Ryujinx)

This is the recommended method of using the patch as it is what I'm using to test it during development.

The Switch emulator [Ryujinx](https://ryujinx.org/) is compatible with the game and the patch, and should perform perfectly even on lower-end hardware.

To install the game, dump it from your Switch, then place the NSP/XCI file into any of the directories listed under Options -> Settings -> General -> Game Directories (add one if there's none listed). To install the patch, [download it](../../releases/latest/download/patch.zip),
then choose File -> Open Ryujinx Folder. Extract the "mods" folder there (the whole folder, not just its contents).

You may get sound stuttering when playing with the OpenAL sound backend. Switch to SDL2 or SoundIO if that happens.

### On PC (via Yuzu)
Another Switch emulator, [Yuzu](https://yuzu-emu.org), is also compatible with the game and the patch.

However, Yuzu does not follow Atmosphère mod conventions, and therefore requires the patch to be modified to work with it.

I have added a tool that will perform the modification for you. First, [download](../../releases/latest/download/patch.zip) the patch.
Next, extract the entire archive into any location that is convenient for you.
Finally, double-click the `prepare_yuzu.bat` file (if you are on Linux, run `prepare_yuzu.sh` with bash instead).

After a short while, a `yuzu_mod` folder will be generated. Now, open Yuzu, right-click the game and choose "Open Mod Data Location".
Move the entire `yuzu_mod` folder there (not just its contents).

Note that yuzu may perform worse or even crash on systems with less than 16GB of RAM, while Ryujinx can handle the game fine in that case.

If you are unsure which emulator to go with, go with Ryujinx. This Yuzu section is here only for those who already play *other* Switch games on Yuzu, so that they aren't inconvenienced with switching between different emulators just for the sake of this patch.

### On Nintendo Switch (the actual hardware)

If you want to play the game on your Nintendo Switch hardware, it will need Atmosphère installed on it. If you don't have Atmosphère already, please look it up to see if
it's compatible with your Switch model and install it if it is.
Afterwards, [download](../../releases/latest/download/patch.zip) the patch, rename `mods` to `atmosphere` and copy it to your SD card.
The next time the game starts, it should be in English.

I don't recommend this approach for now as the patch is still in active development and you're potentially going to murder your SD card updating it all the time. Once the patch is finished, this method of playing should be perfectly viable.

### On Sony PlayStation 4 and 5

Applying the patch on these platforms is *theoretically* possible, though only partially: only the `patch.rom` can be used.
Unfortunately, this means that the tips menu will not work correctly, and the minigame in Episode 8 will remain in Japanese: those things require exefs modifications, and I have no idea how to implement something similar for the PS4 version of the game.

Additionally, I have not tested the patch on these consoles, nor do I actually have any idea how to install it. If you have some sort of instructions I could put here, please let me know.

Finally, trophies will almost certainly not work with the patch installed.

In short -- the patch *might* work on PlayStation, maybe, sort of, but no promises whatsoever. I strongly recommend using the Switch version of the game instead.

### On Sony PlayStation 3 and PSP

The patch is **not compatible** with the versions of Umineko released on this hardware. At all. Don't even bother trying.
