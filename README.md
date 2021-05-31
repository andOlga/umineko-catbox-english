# English patch for Umineko Catbox (work in progress)

## Project description
This is an English patch for Umineko When They Cry: The Symphony of Catbox and Dreams, the console version
of Umineko on PlayStation 4 and Nintendo Switch.

This patch is meant to be used on the **actual console releases of the game**. It is ***not* a standalone application**.

The goal of the patch is to translate all text-based story content, character bios and tips.
Backgrounds with text on them are unfortunately out of scope, at least for now.
I have no idea how the hell to generate .PIC files that Entergram uses for backgrounds.
If anyone knows, please tell me!

## Progress

This patch is a work in progress. The current state of the content is as follows:

- [ ] UI
  - [ ] Text
  - [ ] Images (that have text on them)
- [ ] Rondo of Witch and Reasoning (Question Arcs)
  - [ ] Episode 1: Legend of the Golden Witch
  - [ ] Episode 2: Turn of the Golden Witch
  - [ ] Episode 3: Banquet of the Golden Witch
  - [ ] Episode 4: Alliance of the Golden Witch
- [ ] Nocturne of Truth and Illusions (Answer Arcs)
  - [ ] Episode 5: End of the Golden Witch
  - [ ] Episode 6: Dawn of the Golden Witch
  - [ ] Episode 7: Requiem of the Golden Witch
  - [ ] Episode 8: Twilight of the Golden Witch
- [ ] Symphony of Catbox and Dreams (new content)
  - [ ] Letter from Bernkastel
  - [ ] The Witches' Tanabata Isn't Sweet
  - [ ] Game Master Battler!
  - [ ] Jessica's Mother's Day Present
  - [ ] Jessica and the Love Charm
  - [ ] Memoirs of the ΛΔ
  - [ ] Notes from a Certain Chef
  - [ ] Labor Thanksgiving Day Gifts
  - [ ] The Seven Sisters' Valentine
  - [ ] Beatrice's White Day
  - [ ] Cornelia, the New Priest
  - [ ] Whose tea party?
  - [ ] Valentine Letters
  - [ ] To Mount Purgatory, Sakutaro!
  - [ ] Arigato for 556
  - [ ] A Certain Witch Hunter's Interview Tape
  - [ ] Letter from a Summoner
  - [ ] Important Facts Concerning Magic
  - [ ] Angel of 17 Years East Shi-44a
  - [ ] Jessica and the Killer Electric Fan
  - [ ] Forgery #XXX
  - [ ] Our Confession
  - [ ] Last Note of the Golden Witch

My intent is to prioritise the new content first. This is because there already is a very competent port of the PS3 versions of Rondo and Nocturne to PC,
which can be used for playing in English. Its name is [Umineko Project](https://umineko-project.org). Please read their version until I'm done.



## Applying the patch

### Switch (emulation)

The Switch emulator [Ryujinx](https://ryujinx.org/) is compatible with the game and the patch. To install the game, dump it from your Switch, then place the NSP/XCI file into any of the directories listed under Options -> Settings -> General -> Game Directories (add one if there's none listed). To install the patch, [download it](../../releases/latest/download/patch.zip),
right-click the game in your game list and choose "Open mods directory". Extract the archive there, preserving the directory structure.

You may get sound stuttering when playing with the OpenAL sound backend. Switch to SoundIO if that happens.

yuzu is currently not compatible with the game. While it does boot, it crashes after a few minutes of play,
and the sound stuttering issue is also present but has no resolution on that emulator. For now, I'd recommend to avoid this emulator.

### Switch (hardware)

If you want to play the game on your Nintendo Switch hardware, it will need Atmosphère installed on it. If you don't have Atmosphère already, please look it up to see if
it's compatible with your Switch model and install it if it is.
Afterwards, [download](../../releases/latest/download/patch.zip) the patch and place the `patch.rom` file in `atmosphere/contents/01006a300ba2c000/romfs/` on your SD card.
The next time the game starts, it should be in English.

### PS4/PS5

The patch should work on PS4 and PS5 as the game uses the same file formats as the Switch version (at least as far as the patch is concerned).
However, I have no idea how to actually apply the patch on these consoles. If you have usable instructions, please let me know.


### PS3/PSP

The patch is **not compatible** with the versions of Umineko released on this hardware. At all. Don't bother trying.
