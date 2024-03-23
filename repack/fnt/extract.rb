require 'fileutils'
require 'csv'
require 'stringio'
require 'json'

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
path = ARGV[0] # Input .fnt file
output_path = ARGV[1] # Output folder
# Specify `manifest-only` as the last argument to skip exporting the individual
# glyphs
manifest_only = (ARGV[2] == "manifest-only")

fnt_file = FntReader.new(open(path, 'rb'))

FileUtils.mkdir_p output_path

def decompress_glyph(glyph_data, size)
  bytes = glyph_data.bytes
  HiguCompression.decompress(bytes, 6)
end

def decompressed_to_png(decompressed, width, height)
  str = decompressed.map { |alpha| [0xff, 0xff, 0xff, alpha] }.flatten.pack('C*')
  ChunkyPNG::Image.from_rgba_stream(width, height, str)
end

manifest = {} # Glyphs by their index
lookup = {} # Glyphs by their address

puts "Found #{fnt_file.header.length} glyphs, #{fnt_file.header.uniq.length} unique"

fnt_file.header.each_with_index do |e, i|
  start_time = Time.now
  glyph_index_hex = i.to_s(16).rjust(4, '0')
  filename = glyph_index_hex + "_" + e.to_s(16)
  glyph_path = File.join(filename[0..1], filename)

  if lookup.key?(e)
    glyph = lookup[e]
  else
    offset_x, offset_y, crop_width, crop_height, frame_width, val6, data_width, data_height, bytes_size, glyph_data = fnt_file.read_glyph_by_address(e)
    decompressed = decompress_glyph(glyph_data, data_width * data_height * 2)

    glyph = Glyph.new(glyph_index_hex, e, glyph_path, offset_x, offset_y, crop_width, crop_height, frame_width, val6, data_width, data_height, decompressed)
    lookup[e] = glyph
  end

  manifest[i] = glyph
  next if manifest_only

  raw_path = File.join(output_path, "raw", glyph_path + ".dat")
  FileUtils.mkdir_p File.dirname(raw_path)
  raw_file = open(raw_path, 'wb')
  raw_file.write(glyph_data)
  raw_file.close

  png_time = Time.now
  if png_available
    image = decompressed_to_png(glyph.decompressed, glyph.data_width, glyph.data_height)

    png_path = File.join(output_path, "1x", glyph_path + ".png")
    FileUtils.mkdir_p File.dirname(png_path)
    png_file = open(png_path, 'wb')
    image.write(png_file)
    png_file.close
  end

  # TODO: smaller sizes of glyphs

  puts "Wrote glyph file #{filename} in #{Time.now - start_time} seconds (of which png encoding: #{Time.now - png_time} seconds)"
end

File.write(File.join(output_path, "data.rb_marshal"), Marshal.dump(manifest))

manifest.each do |k, v|
  v.decompressed = nil
end
File.write(File.join(output_path, "manifest.rb_marshal"), Marshal.dump(manifest))

json_friendly_manifest = Hash[manifest.map { |k, v| [k, v.to_h.except(:decompressed)] }]
File.write(File.join(output_path, "manifest.json"), JSON.pretty_generate(json_friendly_manifest))
