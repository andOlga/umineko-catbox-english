# English patch for Umineko Catbox (UCE)

[![Patch build](https://github.com/ooa113y/umineko-catbox-english/actions/workflows/main.yml/badge.svg)](https://github.com/ooa113y/umineko-catbox-english/actions/workflows/main.yml)

## Project description
This is an English patch for Umineko When They Cry: The Symphony of Catbox and Dreams, the console version
of Umineko on PlayStation 4 and Nintendo Switch.

This patch is meant to be used on the **actual console releases of the game**. It is ***not* a standalone application**.

This project is made possible by the **excellent** [kaleido](https://gitlab.com/Neurochitin/kaleido/-/tree/saku/) tool by Neurochitin, which allows for modding of Entergram games, as well as the fact that Entergram added built-in mod support to Umineko (for reasons unknown). This allows for a clean build/install process and helps me avoid distributing the entire game.

## Progress
The final goal of the patch is to translate the entire game into English, including all of the new content.
However, it is currently in very early stages, and it will take quite a bit of time until that goal is reached.

Currently, the "main" content (stuff that was present in all previous releases of Umineko,
i.e. Episodes 1-8 and their respective open and hidden tea parties) is translated, but untested and might crash or act weird.

However:

- The bonus content has not been touched yet and I'll get around to it when I finish testing and tweaking the main episodes.
- The menus are in Japanese.
- Some of the CGs have Japanese text on them.
- TIPS and character descriptions are in Japanese.

This will be addressed later.

## How does this compare to ...?

There's like a thousand different versions of Umineko. Very confusing, I understand. So here's a quick comparison of how this version will stack up against its main competitors (once it's finished):

|Feature|UCE|[Umineko Project](https://umineko-project.org)|[07th-Mod](https://07th-mod.com)|Steam release
|-|-|-|-|-|
|Content coverage|Rondo, Nocturne, Symphony|Rondo, Nocturne|Rondo, Nocturne|Rondo & Nocturne (full)<br>Symphony (partial)
|Sprites|Animated Switch/PS4 sprites|Animated *or* static PS3 sprites<br>(fewer expressions but otherwise identical to Switch/PS4)|Static PS3 sprites<br>Original/Steam sprites|Original/Steam sprites
|Backgrounds|Animated|Animated|Static|Static|
|CGs|Yes|Yes|Yes|Sort of (they exist in files but are never shown...)
|Text display|ADV<br>(small textbox at the bottom of the screen)|ADV|ADV or NVL|NVL<br>(text covers whole screen)
|Voice acting|Yes|Yes|Yes|Yes<br>(need "voice-only" patch from 07th-Mod)
|Backlog|Advanced<br>(jump to line/chapter, replay voice)|Advanced|Basic<br>(only view past text)|Basic
|Resolution|1920x1080|1920x1080|1920x1080|1280x960
|Languages|English<br>(Japanese can be played without the patch 😆)|English, Russian, Portuguese, Chinese<br>Japanese **not** supported|English, Japanese|English, Japanese
|Targeted platforms|Switch, PS4, PS5<br>PC (via emulation)|PC, Android, iOS|PC|PC
|Input methods|Controller, touch|Keyboard, mouse|Keyboard, mouse, controller|Keyboard, mouse, controller

My intent is for UCE to be the "perfect", definitive way of experiencing Umineko in English, short of an official release by Entergram. Should that happen, this project will be taken down in favour of the official release. However, Entergram's track record with English releases is non-existent, and licensing Umineko for the West would be a nightmare, so the probability of that happening is abysmally close to zero.

This is a lofty goal. However, having the power of the actual console release at my fingertips, I no longer have to build something that sort of kind of *feels* like the console version of Umineko. Instead, I have the real, authentic thing here to cut open, tear apart and sew back together. This means that once the actual text insertion work is complete, there will be nothing left to do -- no possible improvements to make.


## Applying the patch

### On PC (via Switch emulation)

The Switch emulator [Ryujinx](https://ryujinx.org/) is compatible with the game and the patch, and should perform perfectly even on lower-end hardware.
This is the recommended method of using the patch.

To install the game, dump it from your Switch, then place the NSP/XCI file into any of the directories listed under Options -> Settings -> General -> Game Directories (add one if there's none listed). To install the patch, [download it](../../releases/latest/download/patch.zip),
right-click the game in your game list and choose "Open mods directory". Extract the archive there, preserving the directory structure.

You may get sound stuttering when playing with the OpenAL sound backend. Switch to SoundIO if that happens.

yuzu is currently not compatible with the game. While it does boot, it crashes after a few minutes of play,
and the sound stuttering issue is also present but has no resolution on that emulator. For now, I'd recommend to avoid this emulator.

### On Nintendo Switch (the actual hardware)

If you want to play the game on your Nintendo Switch hardware, it will need Atmosphère installed on it. If you don't have Atmosphère already, please look it up to see if
it's compatible with your Switch model and install it if it is.
Afterwards, [download](../../releases/latest/download/patch.zip) the patch and place the `patch.rom` file in `atmosphere/contents/01006a300ba2c000/romfs/` on your SD card.
The next time the game starts, it should be in English.

### On Sony PlayStation 4 and 5

The patch should work on PS4 and PS5 as the game uses the same file formats as the Switch version (at least as far as the patch is concerned).
However, I have no idea how to actually apply the patch on these consoles. If you have usable instructions, please let me know.


### On Sony PlayStation 3 and PSP

The patch is **not compatible** with the versions of Umineko released on this hardware. At all. Don't bother trying.
