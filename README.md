# English patch for Umineko Catbox (work in progress)

## Project description
This is an English patch for Umineko When They Cry: The Symphony of Catbox and Dreams, the console version
of Umineko on PlayStation 4 and Nintendo Switch.

This patch is meant to be used on the **actual console releases of the game**, whether on actual consoles or on an emulator, it is **not a standalone application**.

The goal of the patch is to translate all text-based story content, character bios and tips.
Backgrounds with text on them are unfortunately out of scope, at least for now.
I have no idea how the hell to generate .PIC files that Entergram uses for backgrounds.
If anyone knows, please tell me!

## Progress

This patch is a work in progress. The translations will be added and published in the following order:

1. Hane.
2. Saku (new content specifically introduced in this release).
3. Tsubasa. 
4. Rondo.
5. Nocturne.

In other words, my intent is to prioritise the new content first. This is because there already is a very competent port of the PS3 versions of Rondo and Nocturne to PC,
which can be used for playing in English. Its name is [Umineko Project](https://umineko-project.org). Please read their version until I'm done.

<!-- TODO: put table here -->

## Applying the patch

### Switch (hardware)

If you want to play the game on your Nintendo Switch hardware, it will need Atmosphère installed on it. If you don't have Atmosphère already, please look it up to see if
it's compatible with your Switch model and install it if it is.
Afterwards, [download](../../releases/latest/download/patch.zip) the patch and place the `patch.rom` file in `atmosphere/contents/01006a300ba2c000/romfs/` on your SD card.
The next time the game starts, it should be in English.

### Switch (emulation)

The Switch emulator [Ryujinx](https://ryujinx.org/) is compatible with the game and the patch. To install the patch, [download it](../../releases/latest/download/patch.zip),
right-click the game in your game list and choose "Open mods directory". Extract the archive there, preserving the directory structure.

You may get sound stuttering when playing with the default OpenAL sound backend. Switch to SoundIO if that happens.

yuzu is currently not compatible with the game. While it boots, it crashes after a few minutes of play,
and the sound stuttering issue is also present but has no resolution on that emulator. Avoid it.

### PS4/PS5

The patch should work on PS4 and PS5 as the game uses the same file formats as the Switch version (at least as far as the patch is concerned).
However, I have no idea how to actually apply the patch on these consoles. If you have usable instructions, please let me know.
