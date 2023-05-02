This project is dedicated, in its entirety, to my beloved Tara.

Reading Umineko together, with this patch, while it was still being worked on,
was one of my best -- and, tragically, last -- memories with her. It is a memory I will treasure forever.

My original decision was to preserve everything about that experience, as perfectly as possible.
That included the imperfections of the patch, the various minor text issues here and there.

This decision still stands, in part. However, I also now realise that she wouldn't want our hard work to be abandoned in an unfinished state,
that she would want others to experience a truly "perfect" version of this incredible story.

So I shall do both. The [master](https://github.com/andOlga/umineko-catbox-english/tree/master) branch is left as-is, untouched, at the day of her passing, save for this notice at the top.
The release that most closely corresponds to this state is [v9.9.99999](https://github.com/andOlga/umineko-catbox-english/releases/tag/v9.9.99999).

All of the new development on this project shall happen on the `rebirth` branch.

Rest in peace, Tara.

And may you live on in everyone's hearts, for all eternity.
May your name be forever engraved on the cold steel of the Web.
May its sound endlessly permeate its cables and frequencies.

I love you, my heart.

---

Note: the **canonical link** for this project is [https://andolga.github.io/umineko-catbox-english](https://andolga.github.io/umineko-catbox-english). Please **DO NOT** link directly to any other part of the project, including its downloads.

# English patch for Umineko Catbox

This is an English patch for Umineko When They Cry: The Symphony of Catbox and Dreams, the console version
of Umineko on Nintendo Switch.

This patch is meant to be used on the **actual console release of the game**. It is ***not* a standalone application**.

## Credits

Besides me, the following people have *directly* contributed to this project:
- My beloved heart, Tara, who was the brightest star that ever shone in my life. Rest in peace, my love.
- [@DoctorDiablo](//github.com/doctordiablo), translating the Witch Hunter's Interview Tape story.
- [@silverwolf-waltz](//github.com/silverwolf-waltz), helping port over the translations for Hane and Saku.
- [@Quplet](//github.com/quplet), providing help with porting some of the main episodes.
- [LHCollider](https://www.youtube.com/lhcollider), helping with testing.

Furthermore, this patch would be impossible without the resources and tools provided by the the following projects:

- [kaleido](https://gitlab.com/Neurochitin/kaleido/-/tree/saku/) by Neurochitin, which can decompile and recompile the SNR script format used by the game, as well as generate the `patch.rom` files that can be used to replace files in the base game.
- [enter_extractor](https://github.com/07th-mod/enter_extractor) by TellowKrinkle, which can extract files from the base game's `data.rom` format, as well as generate `pic` and `txa` files used to store the game's images.
- [HigurashiENX](https://github.com/masagrator/HigurashiENX) by MasaGratoR, which is a similar translation patch for the Switch version of Higurashi. Specifically, the IPS patch generation scripts from that project were used to translate some of the text hardcoded into the executables of the game.
- [Umineko Project](https://umineko-project.org), a similar translation work done for the PS3 version of Umineko, which serves as the base for the translated script and images used in the patch.
- [Umineko Tsubasa English Patch](https://uminekotsubasa.github.io/), which served as the initial source for the translation of the Tsubasa arcs present in the PC version (these were *heavily* edited to be consistent with the main story as well as with each other).
- ArsMagica's English patch for Hane, now lost to time, which served as the initial source for the translation of the Hane arcs.
- [The 07th-Expansion wiki](https://07th-expansion.fandom.com/wiki/07th_Expansion_Wiki), which had a translation for Our Confession as well as most of the new Tsubasa stories.
- A random person who just showed up on the Hinamizawa Discord one day with the nickname of "last-note", dumped a full translation of Last Note, and left.
- The original translation of the PC version of Umineko by [The Witch Hunt](https://witch-hunt.com). While their work isn't being used directly, without these people Umineko would have never made it to the West in any form at all.
- And, of course, the game itself, created by 07th-Expansion and producted (sic) by Entergram. Please buy the game on the [eShop](https://store-jp.nintendo.com/list/software/70010000012343.html) to support the creators.
  - You can *technically* also buy the game on [PSN](https://store.playstation.com/ja-jp/product/JP0741-CUSA16973_00-UMINEKOSAKUZZZZZ), though that version isn't fully compatible with the patch, and the parts that *may be* compatible (romfs changes) are untested. If you get that one, you're on your own in trying to get it to run.
  - There are also a few various versions of Umineko native to PC. How good they are varies depending on the version you dig up, but none of them properly support the creators, none of them are compatible with this patch, and all of them have various missing content compared to the console release of the game.
    - This includes the Steam version, as it is a re-release of the old indie version of Umineko, and as such does not include any of the console version's improvements. Because of this, buying this release does not help support the creators of the console version in any way, though it *does* help support the author and the original creator of the series, Ryukishi07. The Steam version is also not compatible with this patch.

## Applying the patch

The game, and this patch, can be played either on PC, via a Switch emulator
(both Ryujinx and Yuzu work well with the patch, so choose whichever you prefer),
or via an ENTERGRAM engine source port,
or on a hackable Nintendo Switch, via Atmosphère. Please follow the below instructions to get the patch set up.

Note that to play on PC, you will need to acquire an NSP of the base game.

To comply with US laws, you have to buy the game on the [eShop](https://store-jp.nintendo.com/list/software/70010000012343.html) and dump it using [nxdumptool](https://github.com/DarkMatterCore/nxdumptool) from a hackable Nintendo Switch to obtain a legal copy for emulation. Software distribution laws in other countries may vary.

### On PC (using Ryujinx)

The Switch emulator [Ryujinx](https://ryujinx.org/) is compatible with the game and the patch.

To set Ryujinx up, you will need a copy of the `prod.keys` file dumped from a hackable Nintendo Switch, the Nintendo Switch firmware, and the game itself. Having acquired these, you may [follow their guide](https://github.com/Ryujinx/Ryujinx/wiki/Ryujinx-Setup-&-Configuration-Guide) to finish your configuration and add the game to the emulator, but please ignore the "Managing mods" section as this patch has a somewhat more complicated structure and cannot be simply added to a per-game folder like they recommend.

To install the patch, [download](https://github.com/andOlga/umineko-catbox-english/releases/latest/download/patch_atmos.zip) the Atmosphère version (Ryujinx is 100% Atmosphère-compatible),
<br>then choose File -> Open Ryujinx Folder. Navigate to the "mods" directory and extract the entire archive to that location. If the "mods" directory does not exist, create it first.

### On PC (using shin)

Note: **this method doesn't work yet** as shin is still in early development, but it may become the best way to play in the near future, so it's documented here. You may want to just read the Ryujinx/Yuzu sections for now though.

[shin](https://github.com/DCNick3/shin) is a complete port of ENTERGRAM's engine to PC, allowing you to experience Umineko without the overhead of emulation.

To play the game on shin, you will need to extract the `data.rom` file from the base game. Follow the Ryujinx instructions above, but instead of actually running the game, right-click it in the emulator, choose "Extract Data", then "RomFS". It will likely take a while, but when it tells you that it's done, you will find the `data.rom` file in the folder you selected. Use it to set up shin as per their instructions.

Next, [download](https://github.com/andOlga/umineko-catbox-english/releases/latest/download/patch_atmos.zip) the Atmosphère version of the patch, and navigate to `contents/01006a300ba2c000/romfs/` inside the archive. Take the `patch.rom` file and place it near the `data.rom` in your shin set-up, then run the game.

Once again: **THIS DOES NOT WORK YET**. Please wait until shin development progresses further.

### On PC (using Yuzu)
Another Switch emulator, [Yuzu](https://yuzu-emu.org), is also compatible with the game and the patch.

**WARNING:** Many users have reported to me that they have issues with the sound when playing the game on Yuzu. This isn't a universal occurence, but it's common enough to mention it. Unfortunately, there is no known fix for this problem. If this happens to you, please use Ryujinx instead.

To set Yuzu up, you will need a copy of the `prod.keys` file dumped from a hackable Nintendo Switch and the game itself. Once you have acquired the keys, navigate to File -> Open Yuzu folder, then find (or create) the subfolder called "keys" inside that and paste the file there. Restart Yuzu and double-click the giant empty rectangle in the main yuzu window to add your game folder.

To install the patch, [download](https://github.com/andOlga/umineko-catbox-english/releases/latest/download/patch_yuzu.zip) the Yuzu version,
<br>then right-click the game in Yuzu, choose "Open Mod Data Location" and extract the entire archive there.

### On Nintendo Switch (the actual hardware)

If you want to play the game on your Nintendo Switch hardware, it will need [Atmosphère](https://github.com/Atmosphere-NX/Atmosphere) installed on it.
If you don't have Atmosphère already, please see if it's compatible with your Switch model and install it if it is.
Afterwards, [download](https://github.com/andOlga/umineko-catbox-english/releases/latest/download/patch_atmos.zip) the Atmosphère version of the patch and copy it to the "atmosphere" folder on your SD card.
The next time the game starts, it should be in English.

## Developer documentation

Some limited docs for those who wish to contribute to patch development, or perhaps translate the script into another language, are available [here](https://github.com/andOlga/umineko-catbox-english/blob/rebirth/CONTRIBUTING.md).

## Support

If you find a bug in the patch, please use the [issue tracker](https://github.com/andOlga/umineko-catbox-english/issues). If you have a question, please use the [forums](https://github.com/andOlga/umineko-catbox-english/discussions). Note that any modifications to the game that aren't translation-related are explicitly out of scope of this project, please refrain from making such requests. This includes fixing the couple of bugs that are present in the original Japanese release.
