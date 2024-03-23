# This shows a sort-of minimal example of a script that can be compiled to SNR
# and packed to a rom file, and it will be accepted by Kal's engine.
#
# This script assumes that the assets listed below are present in the correct
# places within the rom file, or the game will freeze as soon as it tries to
# load them. If you want to avoid this, you can remove the instructions which
# use the assets

def raw_apply(snr)
  # -- DEFINITIONS --
  snr.mask 'blind'
  snr.mask 'bottom'
  snr.write_masks

  snr.bg 'black', 65535
  snr.bg 'white', 65535
  snr.bg 'red', 65535
  bg_sunset = snr.bg 'bg11b', 65535
  snr.write_bgs

  snr.bustup 'dummy', 4, 100, 0, 0
  bup_fuuka = snr.bustup 'bustup', 0, 65, 0, 30
  snr.write_bustups

  bgm_natsu = snr.bgm 'umib_002', %(夏の扉), 65535
  snr.write_bgms

  se_glass = snr.se 'glassbreak'
  snr.se 'ame001'
  snr.write_ses

  snr.movie 'op1', 65535, 1, 13
  snr.write_movies

  snr.voice 'karin*', 1, 1
  snr.voice 'mina*', 1, 2
  snr.voice 'doremi*', 1, 3
  snr.voice 'fuuka*', 1, 0
  snr.voice '*', 1, 4
  snr.write_voices

  snr.table8_entry 'ev01_苦悶', 133, 134, 94, 96, 98, 99, 100, 102, 104, 105, 106, 108, 109, 111, 114, 117, 119, 121, 123, 124, 125, 127, 128, 130, 131, 132, 137
  snr.write_table8

  snr.table9_entry 0, 1, 0
  snr.write_table9

  # -- SCRIPT --
  s = KalScript.new(snr.current_offset + 8)
  s.ins 0x47, :end_of_script
  s.label :reset # TODO: find out whether some of these instructions are really necessary still
  s.ins 0x91, 0
  s.ins 0x97, 0
  s.ins 0x8a, byte(0)
  s.ins 0x41, byte(0), ushort(17), 0
  s.ins 0x41, byte(0), ushort(18), 0
  s.ins 0x41, byte(0), ushort(19), 0
  s.ins 0x85, 0
  s.ins 0x83, byte(0), 30
  s.ins 0x50

  s.ins 0xff, 's00_prologue start.', byte(0)
  s.label :scene_start
  s.ins 0x4f, :reset, []
  s.ins 0xa2, 0 # Same with these timing ones
  s.ins 0xa3
  s.ins 0x83, byte(0), 60
  s.ins 0xa0, byte(0), ''
  s.ins 0xa0, byte(1), 'Chapter title'
  s.ins 0xa1

  # Start of dialogue. All following lines are optional and can freely be replaced with whatever you desire.
  s.ins 0x86, uint(1), byte(0), '@rA dialogue line'
  s.ins 0x87, byte(127)

  s.ins 0x86, uint(2), byte(2), '水無@r@vmina0001.This is a voiced line which should say 「……う〜ん……もぉ食べられないよぉ……」'
  s.ins 0x87, byte(127)

  s.ins 0x86, uint(3), byte(3), '@rThird line which contains a click wait…@kThere you go'
  s.ins 0x87, byte(127)

  s.ins 0x86, uint(3), byte(3), '@rPlaying some BGM - note how it is from Umineko'
  s.ins 0x90, bgm_natsu, 30, 0, 1000
  s.ins 0x87, byte(127)

  s.ins 0x86, uint(3), byte(3), '@rLoading a background……'
  s.ins 0xc1, 1, byte(2), 0, byte(1), bg_sunset
  s.ins 0x87, byte(127)

  s.ins 0x86, uint(3), byte(3), '@rShowing a bustup sprite…………'
  s.ins 0xc1, 2, byte(3), 0, byte(0xf), bup_fuuka, 0, 0, 0
  s.ins 0x87, byte(127)

  s.ins 0x85, 0x21
  s.ins 0x86, uint(3), byte(3), '@rPlaying a sound effect - and this text is in another position!'
  s.ins 0x95, 1, se_glass, 0, 1, 500, 0, 0
  s.ins 0x87, byte(127)

  s.ins 0x85, 0x00
  s.ins 0x86, uint(3), byte(3), '@rBack to original position． After this line, it should start over'
  s.ins 0x87, byte(127)

  # End of dialogue, go back (or rather, jump forward) to entry point
  s.ins 0x47, :entry_point

  entry_point = s.label :entry_point
  s.ins 0x47, :scene_start
  s.label :end_of_script
  s.ins 0x4f, :reset, []

  # -- END OF SCRIPT --

  snr.write_script(s.data, entry_point, s.dialogue_line_count)
end
