require_relative 'glyph.rb'

# Class to read .fnt files from Entergram's engine
class FntReader
  attr_reader :val1, :size, :val2, :header

  def initialize(file)
    @file = file
    read_file_header
  end

  # Reads a glyph by its numeric Unicode codepoint
  def read_glyph_by_codepoint(codepoint)
    read_glyph_by_address(@header[codepoint])
  end

  # Reads a glyph by numeric address within the file
  def read_glyph_by_address(address)
    @file.seek(address)
    offset_x, offset_y = @file.read(2).unpack('cc')
    crop_width, crop_height = @file.read(2).unpack('CC')
    frame_width, val6 = @file.read(2).unpack('CC')
    raise "val6 of glyph at #{address} is not 0 but #{val6}" if val6 != 0

    data_width, data_height = @file.read(2).unpack('CC')
    bytes_size, _ = @file.read(2).unpack('S<')
    glyph_data = @file.read(bytes_size)

    [
      offset_x, offset_y,
      crop_width, crop_height,
      frame_width, val6,
      data_width, data_height,
      bytes_size,
      glyph_data
    ]
  end

  private

  def read_file_header
    magic = @file.read(4)
    raise "Not an FNT4 file, magic bytes were: #{magic}" if magic != 'FNT4'

    @val1, @size, @val2 = @file.read(0xc).unpack('L<L<L<')
    @header = @file.read(0x40000).unpack('L*')
  end
end

# Class to write .fnt files for Entergram's engine
class FntWriter
  def initialize(val1, val2)
    @val1, @val2 = val1, val2

    # This will become the file header
    @glyph_table = [nil] * 0xffff
  end

  def set_glyph(codepoint, offset_x, offset_y, crop_width, crop_height,
      frame_width, val6, data_width, data_height, glyph_data)
    encoded = encode_glyph(offset_x, offset_y, crop_width, crop_height,
      frame_width, val6, data_width, data_height, glyph_data)
    @glyph_table[codepoint] = encoded
  end

  def write_to(file)
    file.write("FNT4")
    file.write([@val1, 0, @val2].pack('L<L<L<'))

    # Verify that all glyphs are non-nil
    @glyph_table.each_with_index do |encoded_glyph, codepoint|
      raise "Glyph at codepoint #{codepoint} is nil!" if encoded_glyph.nil?
    end

    # Write glyph data itself
    file.seek(0x40010)
    glyph_addresses = {}
    @glyph_table.uniq.each do |encoded_glyph|
      glyph_addresses[encoded_glyph] = file.pos
      file.write(encoded_glyph)
    end

    size = file.pos

    # Write glyph table at the start
    file.seek(0x10)
    address_list = @glyph_table.map { |e| glyph_addresses[e] }
    file.write(address_list.pack('L<*'))

    # Write size
    file.seek(0x8)
    file.write([size].pack('L<'))
  end

  private

  def encode_glyph(*stuff, glyph_data)
    (stuff + [glyph_data.length]).pack('ccCCCCCCS<') + glyph_data
  end
end
