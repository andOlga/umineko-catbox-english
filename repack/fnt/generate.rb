require_relative 'glyph.rb'
require_relative 'fnt_format.rb'
require_relative '../higu_compression.rb'

begin
  begin
    require 'oily_png' # try more performant native library first
    puts "successfully loaded oily_png"
  rescue LoadError
    require 'chunky_png'
    puts "oily_png is not available, png encoding will be very slow"
  end
  png_available = true
rescue LoadError
  puts "chunky_png or oily_png is not available, no png files will be written"
  png_available = false
end

# Arguments:
# 1. Reference .fnt file which will be used as a fallback
# 2. Folder from which new glyphs will be taken
# 3. Output path for .fnt file
# 4-5. X and Y glyph offsets (optional, will otherwise be set to the default
#      values from newrodin)
reference_file_path, new_glyph_folder_path, out_path, default_x_offset, default_y_offset = ARGV
default_x_offset = default_x_offset&.to_i || -8
default_y_offset = default_y_offset&.to_i || 88

reference_file = FntReader.new(open(reference_file_path, 'rb'))
out_file = FntWriter.new(reference_file.val1, reference_file.val2)

# Add glyphs from reference file first
[*0x0000..0xffff].each do |codepoint|
  offset_x, offset_y, crop_width, crop_height, frame_width, val6, data_width, data_height, _, glyph_data = reference_file.read_glyph_by_codepoint(codepoint)
  out_file.set_glyph(codepoint, offset_x, offset_y, crop_width, crop_height,
    frame_width, val6, data_width, data_height, glyph_data)
end

# Converts a loaded PNG image to an array of 8-bit alpha values.
def png_to_8bit(png_image)
  bytes = png_image.pixels.map do |colour|
    unless ChunkyPNG::Color.grayscale?(colour)
      raise "Input PNG file at #{png_path} has non-grayscale pixels"
    end

    # Invert; black areas from the input file should be 0xff in the output
    255 - ChunkyPNG::Color.r(colour)
  end
end

FORMATS = [["1x", 128], ["0.5x", 64], ["0.25x", 32], ["0.125x", 16]]

# Load new glyphs from folder
glyph_folders = Dir[File.join(new_glyph_folder_path, "glyph_*")]
glyph_folders.each do |glyph_folder_path|
  # Parse folder name (called like "glyph_8243_316")
  _, *stuff = File.basename(glyph_folder_path).split('_')
  codepoint, advance_width, em, overrun_above, overrun_below, overrun_left = stuff.map(&:to_i)

  data_width, data_height = nil, nil

  png_images = FORMATS.map do |format, format_height|
    path = File.join(glyph_folder_path, format + ".png")
    image = ChunkyPNG::Image.from_file(path)

    # Set the data width and height to the next number divisible by 16 greater
    # than the respective dimension of the first image
    data_width = (image.width + 16) & 0xfff0 if data_width.nil?
    data_height = (image.height + 16) & 0xfff0 if data_height.nil?

    raise "Image height too small (#{image.height} < #{format_height})" if image.height < format_height

    inv_scale = 128 / format_height
    target_width = data_width / inv_scale
    target_height = data_height / inv_scale

    image.crop!(
      0, 0, # x, y
      [image.width, target_width].min, # width
      [image.height, target_height].min # height
    )

    # Resize image (filling with white to the right) so that it matches the data
    # width shifted down according to the format size
    new_image = ChunkyPNG::Canvas.new(target_width, target_height,
      ChunkyPNG::Color::WHITE)
    new_image.compose!(image)

    new_image
  end

  glyph_data = png_images.map { |image| png_to_8bit(image) }.flatten
  compressed = HiguCompression.compress_naive(glyph_data, 6).pack('C*')

  width, height = png_images[0].width, png_images[0].height

  # Default values for newrodin, these work pretty well with other fonts too
  x_offset, y_offset = default_x_offset, default_y_offset

  if overrun_left > 0
    # x offset: positive =^= right
    x_offset -= overrun_left * 128 / em

    # If the glyph is shifted to the left, we need to adjust the advance width
    # by the same amount so that the next character is not placed too closely.
    advance_width += overrun_left * 128 / em
  end

  # y offset: positive =^= up
  y_offset += overrun_above * 128 / em if overrun_above > 0

  out_file.set_glyph(
    codepoint,
    x_offset, y_offset, # x and y offsets
    width, height, # crop width and height
    advance_width * 128 / em, # frame width
    0, # val6
    data_width, data_height, # data width and height
    compressed
  )

  puts "Replaced glyph #{[codepoint].pack('U')} (#{codepoint})"
end

# Export
out_file.write_to(open(out_path, 'wb'))
