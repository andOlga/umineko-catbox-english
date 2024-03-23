# The definition of the Glyph struct, which is also used by other code
Glyph = Struct.new(:index_hex, :address, :path, :offset_x, :offset_y,
  :crop_width, :crop_height, :frame_width, :val6, :data_width,
  :data_height, :decompressed)
