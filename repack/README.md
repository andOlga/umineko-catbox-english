# Reverse engineering Gensou Rougoku no Kaleidoscope

This is just something I am doing for fun and to get a bit more familiar with reverse engineering and VN scripting. Perhaps eventually a PC port of the VN will come out of it.

The bulk of this project is in the [`read_scenario.rb`](https://gitlab.com/Neurochitin/kaleido/-/blob/saku/snr-reader/read_scenario.rb) file that parses the `main.snr` file from the Switch release. Extracting and converting the other files is possible e.g. with tools from 07th Mod.

The output of the script is an NScripter-style script, specifically targeting 07th-mod's fork of Ponscripter, that aims to eventually reproduce the original functionality of the game. If you instead intend to use the result as a reference, it may be more helpful to modify the script to output something more human-readable; I may add an option for this in the future.

The script also works with Umineko Saku; this is not a given because the two use slightly different script formats, but it did not take too much effort to make it work for both. Plus, the additional information helped me iron out some areas where I was wrong about how things work. I am now relatively confident that (almost) all instructions are parsed correctly. I still have to figure out how most of them are to be interpreted.

It must be noted that while Kal and Saku do not differ that much from each other (see differences section below), both are very different from previous console VN releases using the SNR format. Previously made tools, like Umineko Project's SNR parser, are essentially useless in parsing Kal's and Saku's SNR format (especially the script section), except for some cases where looking at the code gave me some inspiration on how certain things are to be interpreted.

**NEW**: In addition to this one-way parsing transformation, I also added some scripts to *create* SNR and rom files from certain inputs. This allows modding the games relatively easily. For more information, see the readme in the [`rom-repack` folder](https://gitlab.com/Neurochitin/kaleido/-/tree/saku/rom-repack)

## Current status:

These are the supported features for the SNR-to-Ponscripter transformation. Applies to both Kal and Saku in theory, although I usually only test with Kal.

 - [x] Successfully parses the entire file
 - [x] Dialogue
   - [x] Text positioning
   - [ ] Pipe waits
 - [x] Backgrounds
   - [ ] Positioning
   - [ ] Animations
   - [ ] `%TIME%`
 - [x] Sprites (still has a lot of bugs)
   - [x] Positioning
   - [ ] Animations
   - [ ] `%DRESS%`
 - [x] BGM
   - [ ] Fadein/-out
   - [x] "Now playing" text
 - [x] SE
   - [ ] Fadein/-out
 - [ ] Masks
 - [x] Voices
 - [ ] Choices
 - [x] Movies
 - [ ] Menu
 - [ ] Loading, saving
 - [ ] Bonus content

## Differences between Kal and Saku SNR formats

This is not an exhaustive list.

- The bustups are stored slightly differently: in Kal, each bustup only has one name followed by some number values; in Saku, each bustup also has an expression name in addition to the regular one, but there are fewer numbers.
- In Kal, every voice table entry has exactly two number values; in Saku, there can be arbitrarily many (length-prefixed)
- In Saku, the current dialogue ID uses three bytes instead of four.
- The instructions from `0xe0` onwards (except `0xff`) are specific to each game. Kal only uses `0xe0`, Saku uses `0xe0` to `0xe4`
