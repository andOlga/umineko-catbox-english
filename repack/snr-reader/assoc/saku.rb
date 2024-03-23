MODE = :saku

# Defines associations to make the output file more readable.
ADDRESSES = {
  'addr_0x932df' => 'l_scenario_start', # Start of Episode 1

  'addr_0x92d69' => 'f_hide_all_sprites',

  # %px0: slot
  # %px1: sprite id
  # %px2: x position?
  # %px3: y position?
  'addr_0x92d9a' => 'f_show_sprite',

  # %px0: primary background
  # %px1: secondary background shown behind primary (e.g. rain); may be null
  'addr_0x92dcd' => 'f_show_background',
  'addr_0x92def' => 'l_f_show_background_no_secondary',
  'addr_0x92df2' => 'l_f_show_background_primary',

  # %px0:
  'addr_0x926e2' => 'f_mask_transition',
}

RAW_SCRIPT_FIX_OFFSET = 20

REGISTERS = {}

FF_CALLS = {}

SPRITE_SLOT_MAIN = -6 # ?

# Text positioning windows
WINDOWS = {
  0x02 => ['0x02', [
    # textx texty txwdh txhgt fs  spx spy spd bold shad colour_or_image             winx winy
    ' 210,  772,  1510, 278,  50, 0,  0,  0,  1,   1,   "custom/msgbox_char.png",   146, 671',
    ' 210,  772,  1510, 278,  50, 0,  0,  0,  1,   1,   "custom/msgbox_nochar.png", 146, 671',
    390, # horizontal center of character name
    709  # vertical center of character name
  ]],
  0x04 => ['0x04', [
    # textx texty txwdh txhgt fs  spx spy spd bold shad colour_or_image          winx winy winwdh winhgt
    ' 208,  342,  1520, 600,  40, 0,  2,  0,  1,   1,   #555555,                 0,   0,   1919,  1079',
    ' 208,  342,  1520, 600,  40, 0,  2,  0,  1,   1,   #555555,                 0,   0,   1919,  1079',
    1920, 1080 # off screen
  ]],
}

# Which labels should be added in addition to the dynamically generated ones
REQUIRE_LABELS = Set.new([0xb66db, 0x94e83, 0x8780ac])
