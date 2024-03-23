# FontForge script to export the glyphs of a font to a format supported by
# generate.rb. To use, open the font you want to export in FontForge, then do
# File -> Execute Script and paste this script, making sure to set the
# desired output path. Click OK and after a while it should have exported all
# the glyphs.
import fontforge
import pathlib

font = fontforge.activeFont()

out_folder = pathlib.Path("") # change path here
out_folder.mkdir(parents = True, exist_ok = True)

out_formats = [
    ["1x", 127],
    ["0.5x", 63],
    ["0.25x", 31],
    ["0.125x", 15]
]

ascent = font.ascent
descent = font.descent
em = font.em

for glyph in font.glyphs():
    if glyph.unicode > -1:
        xmin, ymin, xmax, ymax = glyph.boundingBox()
        overrun_above = ymax - ascent
        overrun_below = -ymin - descent
        overrun_left = -glyph.left_side_bearing
        # overrun_right nis not relevant for our purposes
        glyph_folder_name = f"glyph_{glyph.unicode}_{glyph.width}_{em}_{overrun_above}_{overrun_below}_{overrun_left}"
        glyph_folder = out_folder / glyph_folder_name
        glyph_folder.mkdir(exist_ok = True)

        for format_name, pixel_size in out_formats:
            glyph.export(str(glyph_folder / f"{format_name}.png"),
                         pixelsize = pixel_size)

        print(f"Exported glyph {glyph_folder_name}")
