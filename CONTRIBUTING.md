This file is here to provide some information to anyone who wants to assist on the patch, or people looking to create stuff like translations.

# Building

To prepare for this work, please first set up the actual game and the patch in their existing form. Make sure they work. This will allow you to test your changes.

Secondly, clone the repository *with submodules*: `git clone https://github.com/ooa113y/umineko-catbox-english --recursive`, or else your builds will fail.

Finally, set up your build environment. This is, unfortunately, not trivial to do, and requires some knowledge of the command line and Linux-like operating systems.

Myself, I build the project with the following:

- OS: [Ubuntu](https://ubuntu.com/) 20.04 (Windows users should use the [WSL](https://docs.microsoft.com/en-us/windows/wsl/install) version of Ubuntu).
Other operating systems are likely going to work fine, but it's untested.
- [Python](https://python.org/) 3.8 (later versions will work fine as well), to generate exefs patches
- [Ruby](https://www.ruby-lang.org/) 2.7 (later versions *should* work, but I'm not 100% sure), to generate the romfs patch
- `zip`, to generate the patch archives.
- Bash, to run the `build.sh` script.

Set all these things up and run `build.sh`. You are going to end up with the same patch archives as what's available in the release section.
Follow the normal installation procedure from that point to update your patch and test your changes.

Alternatively, a GitHub Actions workflow is provided in the repository. You may simply choose to enable actions in your fork, after which you'll be able to build a release by clicking "Run workflow" in the Actions tab, or by `gh workflow run` in the GitHub CLI.
If your workflow isn't particularly heavy and you don't build the patch super often, you might prefer this approach.

Additionally, if you are building locally and using Ryujinx to test, you may define the `$UMINEKO_TARGET` environment variable as the path to your Ryujinx folder,
e.g. `/mnt/c/Users/<your username>/AppData/Roaming/Ryujinx`.
If done correctly, then building the patch will automatically copy it to your Ryujinx folder instead of creating archives for manual extraction.

# Testing

Test any lines of the script you've changed. The quickest way is to select the appropriate Episode, then open the backlog with the X button and find your lines.
Jump to them, check if everything looks fine, then continue your work. If you insist on using save files and playing through the game normally, note that any error in the script
can cause the game to go haywire and erase your save data *completely*. Make backups!

# Editing the script

The main script is stored in the `script.rb` file. Note that this file contains a mix of text and binary data, so you need to use a sane editor for changing it that preserves NUL characters.
I use [Visual Studio Code](https://code.visualstudio.com), but there may be others that work fine.

As a general rule, do not touch any line except those that start with `s.ins 0x86`. These are the lines responsible for displaying text,
and they're the only ones you should be changing.
I currently do not parse any of the other instructions into anything sensible, so what anything else even does is a mystery to me.

Either way, I will not accept any pull requests that modify other lines, since my only goal is translation.
If you are intending to keep your project separate from mine, go ahead and figure out what they do and change them, but do not send PRs in that case.

Inside the `0x86` lines, you will also find a single call to `s.layout()` containing the actual text. This is what you should be editing.

All strings in the file use single-quote syntax, so make sure to escape apostrophes inside the text (i.e. replace `'` with `\'` before you do anything).

## Tags

Inside the text, you will find several "tags". These change text behaviour in one way or another. All tags start with `@`.

Some tags exist on their own, like `@r` is a complete tag.

Some tags take arguments. For those, the syntax is `@varg1|arg2|arg3.` (the tag is `@v` and the arguments are `arg1`, `arg2`, and `arg3`; the `.` terminates the tag).

The tags that are used in Umineko, with example arguments, are as follows:

- `@r` forces a line break. Additionally, separates the nametag from the actual displayed text.
- `@w500.` waits for 500 milliseconds before continuing the text.
- `@k` waits for a user to click before continuing in the middle of a line (this is automatic on end of line).
- `@e` ends the line without waiting for a click. If used, this must be the last two characters of the line.
- `@t` causes the text before and after it to appear at the same time, generally used when multiple characters talk over each other.
- `@v29/52200086.` plays the voice line located in the file `voice/29/52200086.nxa`.
- `@c900.` changes the text color to red. The number here is a strange decimal RGB code, ranging from `000` (black) to `999` (white).
- `@c.` is the same thing as `@c999.`, i.e. it changes the text color to white.
- `@z70.` changes the font size to 70% of the normal size. The default size, therefore, is `@z100.`.
- `@{text@}` displays "text" in bold.
- `@[text@]` displays "text" instantly, regardless of the user's text speed setting.
- `@btop text.@<bottom text@>` causes [furigana](https://en.wikipedia.org/wiki/Ruby_character) to render, with "bottom text" being the main, large text at the bottom, and "top text" being the smaller, informative text at the top. This is used mainly for pronounciation guides. Note that "top text", annoyingly, may not include any other tags or the `.` character.
- `@u229.` renders as `å`. This allows to, theoretically, render arbitrary Unicode characters via their decimal code, but you will need to generate new `.fnt` files and manifests for this to actually work, since the default font only supports English and Japanese. The `repack` folder contains the relevant tools and documentation for this. Don't use these unless you are translating the script to another language.
- `@|` and `@y` do *something*. What they do will greatly depend on the actual line they are in. These tags execute arbitrary code in the middle of a line, and this code is defined outside of the line itself. Do not remove these tags from any of the lines, or add extra ones, as it may potentially break the entire game.

With the exception of furigana (`@b`), *leave all tags alone* in appropriate positions in the text, do not try to change them. Just replace the actual Japanese (or English, if you are translating) text. Use the furigana tag when you need to show Japanese text and its pronounciation. This documentation is here to help you understand what the tags do, but do not go wild with them, preserve the original formatting as much as possible.

# Editing the exefs_texts

`exefs_texts.txt` contains text that is hardcoded in the Nintendo Switch executable of the game. This is mainly used for UI text, such as confirmation prompts, but it *also* unfortunately includes BERNKASTEL's game during EP8.

This file is a TSV file. Each row has the format `offset<tab>English text<tab>Japanese text`.
Out of these, the only one you should be changing is the "English text".

The offset is used to replace the correct portion of the executable file, so changing that will result in the game completely breaking.

The Japanese text is used for length validation. 
The English text *must* be the same size as the Japanese text, or lower, in bytes, when encoded as UTF-8.
If the English text is larger (in bytes) than the Japanese version, the replacement will fail.

There is nothing that can be done about this, unfortunately.
This will not cause problems translating into English, since one Japanese character will basically be the same size as *three* English chars,
however, translating to other languages may prove problematic because of this limitation.

As a workaround, do note that the entire text for Bern's game is also mirrored in the actual script file.
You may choose to inform your users of the ability to use the backlog to browse through the script, instead of translating the exefs text,
if your language cannot be reasonably made work with the length requirements.

# Editing images

You will need to build and install [enter_extractor](https://github.com/07th-mod/enter_extractor) for this.

The game includes two types of image files: `.pic`, which is a simple, single-image format used for backgrounds and such,
and `.txa`, which is a more complex multi-image texture format.
There is also `.bup` used by sprites, but there's no conceivable need to ever edit those.

You will need just several commands to make image editing work.

- To convert a PIC file to an editable PNG, use `EnterExtractor file.pic file.png`. Edit the file with your favourite image editor.
- To convert a PNG file back to a PIC, use `EnterExtractor file_original.pic file_new.pic -replace file.png`. You *need* the original PIC file from the base game for this process -- that's `file_original.pic`. The `file_new.pic` will be the edited version that EnterExtractor generates.
- To convert a TXA file to a bunch of images, use `EnterExtractor file.txa prefix`. This will generate images named `prefix_<name from txa>.png`. Edit each of those with your favorite editor.
- To convert the PNGs back to a TXA, use `EnterExtractor file_original.txa file_new.txa -replace prefix`. This likewise requires the original TXA file from the base game for it to work.

Note that PIC images *can* be palleted, and TXA images *must* be. Unpalleted TXAs will render incorrectly. Unpalleted PICs will just take an enormous amount of disk space, but will otherwise work fine. 

For this paletting process to work, the PNG needs to be saved with 256 colors only. This will work fine for all the images in the game that include text, so just remember to check the appropriate setting in your image editor.
