# English patch for Umineko Catbox (UCE)

[![Patch build](https://github.com/ooa113y/umineko-catbox-english/actions/workflows/main.yml/badge.svg)](https://github.com/ooa113y/umineko-catbox-english/actions/workflows/main.yml)

## Project description
This is an English patch for Umineko When They Cry: The Symphony of Catbox and Dreams, the console version
of Umineko on PlayStation 4 and Nintendo Switch.

This patch is meant to be used on the **actual console releases of the game**. It is ***not* a standalone application**.

## Credits

This patch would be impossible without the assistance of the following projects:

- [kaleido](https://gitlab.com/Neurochitin/kaleido/-/tree/saku/) by Neurochitin, which can decompile and recompile the SNR script format used by the game, as well as generate the `patch.rom` files that can be used to replace files in the base game.
- [enter_extractor](https://github.com/07th-mod/enter_extractor) by TellowKrinkle, which can extract files from the base game's `data.rom` format, as well as generate `pic` and `txa` files used to store the game's images.
- [HigurashiENX](https://github.com/masagrator/HigurashiENX) by MasaGratoR, which is a similar translation patch for the Switch version of Higurashi. Specifically, the IPS patch generation scripts from that project were used to translate some of the text hardcoded into the executables of the game.
- [Umineko Project](https://umineko-project.org), a similar translation work done for the PS3 version of Umineko, which serves as the base for the translated script and images used in the patch.
- The original translation of the PC version of Umineko by [The Witch Hunt](https://witch-hunt.com). While their work isn't being used directly, without these people Umineko would have never made it to the West in any form at all.
- And, of course, the game itself, created by 07th-Expansion and producted (sic) by Entergram. Please buy the game on the [eShop](https://store-jp.nintendo.com/list/software/70010000012343.html) or [PSN](https://store.playstation.com/ja-jp/product/JP0741-CUSA16973_00-UMINEKOSAKUZZZZZ) to support the creators.

## Progress
The final goal of the patch is to translate the entire game into English, including all of the new content.
However, it is currently a work in progress, and it will take quite a bit of time until that goal is reached.

Currently, the "main" content (stuff that was present in all previous releases of Umineko,
i.e. Episodes 1-8) has been translated, however, only EPs 1-2 have been thoroughly tested so far.

Your experience with the untested episodes may range from encountering a couple of untranslated sentences here and there to outright crashes. Of course, I am working on testing and fixing the remaining episodes.

Bonus content (Tsubasa, Hane and the new Saku-exclusive stories) has not been touched at all yet. For now, it is fully in Japanese. I will get around to it when the main EPs are done.

## Applying the patch

### On PC (via Switch emulation)

The Switch emulator [Ryujinx](https://ryujinx.org/) is compatible with the game and the patch, and should perform perfectly even on lower-end hardware.
This is the recommended method of using the patch.

To install the game, dump it from your Switch, then place the NSP/XCI file into any of the directories listed under Options -> Settings -> General -> Game Directories (add one if there's none listed). To install the patch, [download it](../../releases/latest/download/patch.zip),
then choose File -> Open Ryujinx Folder. Extract the archive there, preserving the directory structure.

You may get sound stuttering when playing with the OpenAL sound backend. Switch to SDL2 or SoundIO if that happens.

### On Nintendo Switch (the actual hardware)

If you want to play the game on your Nintendo Switch hardware, it will need Atmosphère installed on it. If you don't have Atmosphère already, please look it up to see if
it's compatible with your Switch model and install it if it is.
Afterwards, [download](../../releases/latest/download/patch.zip) the patch, rename `mods` to `atmosphere` and copy it to your SD card.
The next time the game starts, it should be in English.

### On Sony PlayStation 4 and 5

The patch should work on PS4 and PS5 as the game uses the same file formats as the Switch version (at least as far as the patch is concerned).
However, I have no idea how to actually apply the patch on these consoles. If you have usable instructions, please let me know.

This approach is *not* recommended.

On PS4/PS5 the game is likely to crash when entering the tips menu.
This is due to a hardcoded length limit for TIPS, which this patch exceeds.
I can only change this value on the Switch version.

Additionally, a certain part of EP8 will remain untranslated on PS4/PS5, for the same reason.

That said, the game should still be largely playable on these platforms, and will be almost fully translated if patched.


### On Sony PlayStation 3 and PSP

The patch is **not compatible** with the versions of Umineko released on this hardware. At all. Don't bother trying.

## How does this compare to ...?

There's like a thousand different versions of Umineko. Very confusing, I understand. So here's a quick comparison of how this version will stack up against its main competitors (once it's finished):

|Feature|UCE|[Umineko Project](https://umineko-project.org)|[07th-Mod](https://07th-mod.com)|Steam release
|-|-|-|-|-|
|Content coverage|Complete|Main arcs only|Main arcs fully covered,<br>bonus arcs mod started but never finished|Main arcs only
|Sprites|Animated Switch/PS4 sprites|Animated *or* static PS3 sprites<br>(fewer expressions but otherwise identical to Switch/PS4)|Static PS3 sprites<br>Original/Steam sprites|Original/Steam sprites
|Backgrounds|Animated|Animated|Static|Static|
|CGs|Yes|Yes|Yes|Sort of (they exist in files but are never shown...)
|Text display|ADV<br>(small textbox at the bottom of the screen)|ADV|ADV or NVL|NVL<br>(text covers whole screen)
|Voice acting|Yes|Yes|Yes|Yes<br>(need "voice-only" patch from 07th-Mod)
|Backlog|Advanced<br>(jump to line/chapter, replay voice)|Advanced|Basic<br>(only view past text)|Basic
|Resolution|1920x1080|1920x1080|1920x1080|1280x960
|Languages|English<br>(Japanese can be played without the patch 😆)|English, Russian, Portuguese, Chinese<br>Japanese **not** supported|English, Japanese|English, Japanese
|Target platforms|Switch, PS4, PS5<br>PC (via emulation)|PC, Android, iOS|PC|PC
|Controller support|Yes|Yes, but very broken|Yes|Yes

My intent is for UCE to be the "perfect", definitive way of experiencing Umineko in English, short of an official release by Entergram. Should that happen, this project will be taken down in favour of the official release. However, Entergram's track record with English releases is non-existent, and licensing Umineko for the West would be a nightmare, so the probability of that happening is abysmally close to zero.

This is a lofty goal. However, having the power of the actual console release at my fingertips, I no longer have to build something that sort of kind of *feels* like the console version of Umineko. Instead, I have the real, authentic thing here to cut open, tear apart and sew back together. This means that once the actual text insertion work is complete, there will be nothing left to do -- no possible improvements to make.
