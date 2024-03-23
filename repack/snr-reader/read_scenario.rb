require 'set'
require 'digest'
require 'stringio'

require '../utils.rb'

# colourise string
class String; def c(a); "\e[#{a}m#{self}\e[0m"; end; end

# Arguments:
path = ARGV[0] # Input .snr file.
output_path = ARGV[1] # Output file. (Optional)
max_dialogue = ARGV[2] ? ARGV[2].to_i : 100000000 # Maximum amount of dialogue that will be parsed, useful if you are trying to quickly prototype some dialogue-independent functionality
dialogue_path = ARGV[3] # Optional; if present, a file containing only the raw dialogue lines will be written to this location.
base_path = ARGV[4] || '.' # If present, it will read bustups and pics from this path and add their origin positions to lookup tables. This is necessary if you want accurate sprite positioning.
dialogue_path = nil if dialogue_path == 'nil'

$stuff = []

# Calculate the SHA256 value of the given script, to find out which mode to use.
sha256 = Digest::SHA256.hexdigest(File.read(path))
puts "SHA256: #{sha256}"
if sha256 == '1a41c95be7427ddd3397249fde5be56dfd6f4a8cef20ab27a7a648f31e824dfb'
  load './assoc/kaleido.rb'
elsif sha256 == '1537bb6f964e2b3ce5501fc68d86f13b7b483d385f34ea6630a7e4d33758aa82'
  load './assoc/saku.rb'
elsif sha256 == 'f3be6c855e97d0442c9ec610d38e219d3696cf7e5da9c0f1b430d9df6d3f7130'
  load './assoc/konosuba.rb'
else
  MODE = :kal
  ADDRESSES = {}
  REGISTERS = {}
  FF_CALLS = {}
  WINDOWS = {}
  REQUIRE_LABELS = Set.new
  puts "Script not recognised! You are probably trying to load a different SNR file than Kal or Saku. This may or may not work."
end

file = open(path, 'rb')

# Byte lengths represented by Ruby pack/unpack instructions; these are the only supported ones in unpack_read
LENS = {
  's' => [2, true],
  'l' => [4, true],
  'q' => [8, true],
  'C' => [1, true],
  'S' => [2, false],
  'L' => [4, false],
  'Q' => [8, false]
}

BITS = {
  1 => 'byte',
  2 => 'short',
  4 => 'int'
}

# Additional byte mappings for UTF-8 to SHIFT-JIS
SHIFT_JIS_MAPPINGS = {
  "a0" => "\ue110", # Fullwidth space
  "87 55" => "Ⅱ", # Roman numeral 2
  "87 56" => "Ⅲ", # Roman numeral 3
  "87 57" => "Ⅳ", # Roman numeral 4
}

# File references, this is how assets must be stored relative to the output script path.
BG_FOLDER = 'bg'
BG_EXT = '.png'
SPRITE_FOLDER = 'sprites'
BGM_FOLDER = 'bgm'
SE_FOLDER = 'se'
MOVIE_FOLDER = 'movie'

# Used as source folders for bup/pic origin retrieval
BUSTUP_FOLDER = 'bustup'
PICTURE_FOLDER = 'picture'

# If true, certain internal instructions (NCSELECT) are ignored while parsing, as they
# are when playing the game normally. If false, it can be considered as
# "test mode"
# Probably only applies to Kal
SNR_PROD = false

SCREEN_WIDTH = 1920
SCREEN_HEIGHT = 1080

# Prints a set of bytes in the specified colour
def byte_print(array, c = 94)
  Kernel.puts Utils::hexdump(array).c(c)
end

# Stop if we are in the wrong mode (e.g. for specific instructions)
def assert_mode(mode)
  raise "Invalid mode (#{mode}) for current state, expected #{MODE}" if mode != MODE
end

# One of the biggest difference between Kal/Saku and previous games is that
# a new variable-length argument format is used for most instructions, rather
# than constant-length arguments.
# This format can not only represent constant values, but also references to
# registers and function parameters. Constant values are signed, stored in
# two's complement format.
class Varlen
  attr_reader :data, :mode, :value

  def initialize(data)
    @data = data
    @first_byte = data.bytes[0]

    if @first_byte >= 0x80 && @first_byte <= 0x8f
      # Three-byte number
      @mode = :m8
      @value = ((@first_byte & 0xF) << 8) | data.bytes[1]
      @value = @value - 0xfff if @value > 0x800 # Two's complement signed
    elsif @first_byte >= 0x90 && @first_byte <= 0x9f
      # Five-byte number
      @mode = :m9
      @value = ((@first_byte & 0xF) << 16) | (data.bytes[1] << 8) | data.bytes[2]
      @value = @value - 0xfffff if @value > 0x80000 # Two's complement signed
    elsif @first_byte >= 0xb0 && @first_byte <= 0xbf
      # Access a small register (%rx0 to %rxf)
      @mode = :mb
      @value = @first_byte & 0xf
      $stuff << "Register.new(#{@value})"
    elsif @first_byte == 0xc0
      # Access a register larger than %rxf (i.e. %rx10 and onwards)
      @mode = :mc0
      @value = data.bytes[1]
      $stuff << "Register.new(#{@value})"
    elsif @first_byte >= 0xd0 && @first_byte <= 0xdf
      # Access a function parameter
      @mode = :md
      @value = @first_byte & 0xf
      $stuff << "Parameter.new(#{@value})"
    elsif @first_byte == 0xe0
      # Null value
      @mode = :me
      @value = 0
      $stuff << ":null"
    elsif (@first_byte >= 0xa0 && @first_byte <= 0xaf) || (@first_byte >= 0xe1 && @first_byte <= 0xff) # these are, as far as I know, unused
      raise "Invalid varlen first byte: 0x#{@first_byte.to_s(16)}"
    elsif @first_byte >= 0x40 && @first_byte <= 0x7f
      # Seven-bit number (negative)
      @mode = :mraw
      @value = @first_byte - 128
    else
      # Seven-bit number (positive)
      @mode = :mraw
      @value = @first_byte
    end

    $stuff << "#{@value}" if constant?
  end

  # Does it represent a constant, non-null value?
  def constant?
    [:mraw, :m8, :m9].include? @mode
  end

  # Returns the constant value; raises an error if this varlen is not
  # constant. Honestly, this might even mean that the parameter is not even
  # supposed to be a varlen...
  def value!
    raise "Expected constant varlen but got #{self}" unless constant?
    @value
  end

  # Length in bytes of this varlen
  def length
    @data.length
  end

  def to_s
    hex = @data.bytes.map { |e| e.to_s(16).rjust(2, '0') }.join
    "V[#{@mode.to_s}, 0x#{hex}, #{@value}]"
  end
end

# Monkey-patch some methods into IO to make it easier to read certain things from the scenario file
class IO
  # Read some bytes and unpack into an array according to a given unpack
  # format specification.
  # Only supports C/c, S/s, L/l, Q/q at the moment (8, 16, 32, 64 bit, signed
  # or unsigned)
  def unpack_read(str, ignore = false)
    lens = str.chars.map { |chr| LENS[chr] || nil }.compact
    len = lens.map(&:first).sum
    raise "Too long: len = #{len}" if len > 1000
    data = read(len)
    byte_print(data.bytes)
    result = data.unpack(str)
    p result

    unless ignore # Don't add this unpack_read to $stuff, e.g. if we're reading the length of something
      result.each_with_index do |value, i|
        bits, signed = lens[i]
        $stuff << "#{signed ? '' : 'u'}#{BITS[bits]}(#{value})"
      end
    end

    result
  end

  # Read a SHIFT-JIS string of the given length. Must be null-terminated
  # (as all strings are in SNR format)
  def read_shift_jis(len)
    raw = read(len)
    raise 'Not null terminated!' unless raw.chars[-1] == 0.chr

    converter = Encoding::Converter.new('SHIFT_JIS', 'UTF-8')
    result = Utils::convert_with_mappings(converter, raw[0..-2], SHIFT_JIS_MAPPINGS, 'UTF-8')
    $stuff << "'#{result}'"
    p result
    result
  end

  # Read `len` varlen arguments to an instruction (see Varlen class above)
  def read_variable_length(len)
    result = []
    len.times do
      first_byte = read(1)
      if (first_byte.bytes[0] >= 0x80 && first_byte.bytes[0] <= 0x9f) || first_byte.bytes[0] == 0xc0
        # At least two bytes
        second_byte = read(1)
        first_byte += second_byte
        if first_byte.bytes[0] >= 0x90 && first_byte.bytes[0] <= 0x9f
          # Three bytes
          third_byte = read(1)
          first_byte += third_byte
        end
      end
      result << Varlen.new(first_byte)
    end
    # For debug purposes
    result.each { |v| Kernel.puts v.to_s.c(95) }
    result
  end

  def readbyte2
    result = readbyte
    $stuff << "byte(#{result})"
    result
  end

  # Read an asset table
  def read_table(offset, size_prefix = true)
    if offset == 0
      Kernel.puts "Warning: Offset for table is 0! Skipping" # somehow Konosuba does not have a BGM table???
      return
    end

    seek(offset)
    if size_prefix
      table_size, element_count = unpack_read('L<L<')
    else
      element_count, _ = unpack_read('L<')
    end
    element_count.times do |n|
      yield n
    end
  end
end

# Represents an nscripter script file that will be written.
# This class does most of the snr -> nsc transformation.
# If you intend to use a different output format, this is the class you will
# want to change.
class OutFile
  def initialize(address_offset, script_offset, debug = true)
    # Hash of instruction offset => nscripter lines
    @h = {}

    @debug = debug

    @offset = 0
    @address_offset = address_offset # useful when parsing script sections on their own, currently unused
    @script_offset = script_offset # determines when to write the interlude (= start of game section in nsc)
    @require_labels = REQUIRE_LABELS
    @nyi = false

    @known_functions = Set.new
    @known_registers = Set.new
    @known_parameters = Set.new

    @dialogue_lines = []

    # Counts which NScripter variable is to be used next to provide an alias for registers or function parameters.
    @nsc_variable_counter = 50 # reserve first 50 variables for internal use

    @masks = {}
    @backgrounds = {}
    @bustups = {}
    @bgm_tracks = {}
    @sound_effects = {}
    @movies = {}
    @voices = {}
    @table8 = {}
    @table9 = {}

    @characters = {}
    @tips = {}
  end

  attr_accessor :masks, :backgrounds, :bustups, :bgm_tracks, :sound_effects, :movies, :voices, :table8, :table9, :offset10_data, :characters, :offset12_data, :tips
  attr_reader :offset, :script_offset, :dialogue_lines

  def offset=(value)
    @nyi = false
    @offset = value
    @h[@offset] ||= []
  end

  def <<(line)
    if @nyi
      line = ";#{line} ;??"
    end
    @h[@offset] << line
  end

  def debug(line)
    return unless @debug
    @h[@offset] << ";#{line}"
  end

  def newline
    self << ""
  end

  # Write the created data to the given path
  def write(path)
    file = open(path, 'w')

    file.write(File.read('prelude.utf'))

    intermission_written = false

    # assign labels to locations used in jumps
    # combine lines to file, inserting labels
    # write to file
    @h.to_a.sort_by(&:first).each do |k, v|
      if !intermission_written && k >= @script_offset
        file.write(File.read('intermission.utf'))
        intermission_written = true
      end

      if @require_labels.include? k
        file.puts "*#{raw_address(k)}"
      end
      v.each { |line| file.puts line }
    end

    file.write(File.read('coda.utf'))
  end

  # ----------------------------------- #
  # - utility methods for consistency - #
  # ----------------------------------- #

  def register(num)
    return parameter(num & 0xf) if num >= 0x1000 && num <= 0x100f

    unless @known_registers.include? num
      @h[2] << "numalias #{raw_register(num).delete('%')}, #{@nsc_variable_counter}"
      @h[2] << "numalias #{REGISTERS[num].delete('%')}, #{@nsc_variable_counter}" if REGISTERS.key?(num)
      @nsc_variable_counter += 1
      @known_registers << num
    end
    REGISTERS[num] || raw_register(num)
  end

  def raw_register(num)
    "%rx#{num.to_s(16)}"
  end

  def parameter(num)
    unless @known_parameters.include? num
      @h[2] << "numalias #{raw_parameter(num).delete('%')}, #{@nsc_variable_counter}"
      @nsc_variable_counter += 1
      @known_parameters << num
    end
    raw_parameter(num)
  end

  def raw_parameter(num); "%px#{num.to_s(16)}"; end

  def address(num)
    num -= @address_offset
    @require_labels << num
    raw_address(num)
  end

  def addresses(nums)
    nums.map { |num| address(num) }
  end

  def raw_address(num)
    raw = "addr_0x#{num.to_s(16)}"
    ADDRESSES[raw] || raw
  end

  def hex(data)
    if data.is_a? Numeric
      "0x#{data.to_s(16)}"
    elsif data.is_a? String
      data.bytes.map { |e| e.to_s(16).rjust(2, '0') }.join(' ')
    elsif data.is_a? Array
      "[#{data.map { |e| hex(e) }.join(', ')}]"
    end
  end

  # If the given variable length object is constant, it will either return that
  # value itself or, if a block is given, the result of that block called with that value.
  # Otherwise it will return the closest NScripter equivalent to whatever the given varlen represents.
  def nscify(val)
    if val.constant?
      if block_given?
        yield(val.value)
      else
        val.value
      end
    else
      p val.value
      case val.mode
      when :mb
        # short register access
        register(val.value)
      when :mc0
        # long register access
        register(val.value)
      when :md
        # function parameter access
        parameter(val.value)
      when :me
        null
      end
    end
  end

  # Same as nscify, but if the value is equal to a given constant (specified in
  # the mappings by SPRITE_SLOT_MAIN) it will return the current_slot variable
  # instead.
  def nscify_slot(val)
    return "255 - %current_slot" if val.constant? && val.value == SPRITE_SLOT_MAIN

    # TODO: It seems that even apart from SPRITE_SLOT_MAIN, Saku (maybe also
    # Kal) uses negative sprite slots, causing a naive (255 - val) calculation
    # to overflow above 256, which is the maximum number of extended sprites.
    # Using the absolute value here is kind of a hack which probably does not
    # have the exact intended effect, but at least it doesn't crash.
    # A cleaner solution could be to map some of the "center" sprite slots
    # which are likely unused for the most part onto each other, to free up
    # space at the top of the range.
    "255 - #{val.constant? ? val.value!.abs : nscify(val)}"
  end

  # Remove or change characters that would not be allowed in nsc identifiers
  def normalize(str)
    norm = str.tr("１２３４５６７８９０", "1234567890").gsub(/[^A-Za-z0-9_]/, '')
    norm = "X#{norm}" if norm =~ /^[0-9_]/
    norm
  end

  def background(val)
    nscify(val) { |value| raw_background(value) }
  end

  def raw_background(id); "bg_0x#{id.to_s(16)}_#{normalize(@backgrounds[id].name)}"; end

  def bustup(val) # probably unused
    nscify(val) { |value| raw_bustup(value) }
  end

  def raw_bustup(id); "bup_0x#{id.to_s(16)}_#{normalize(@bustups[id].name)}"; end

  def raw_bgm_track(id); "bgm_0x#{id}_#{normalize(@bgm_tracks[id].name1)}_#{normalize(@bgm_tracks[id].name2)}"; end

  def raw_sound_effect(id); "se_0x#{id.to_s(16)}_#{normalize(@sound_effects[id].name)}"; end

  def raw_movie(id); "movie_0x#{id.to_s(16)}_#{normalize(@movies[id].name)}"; end

  def null; "null"; end

  def nyi
    @nyi = true
  end

  # ------------------------------------------------ #
  # - utility methods for frequently-used NSC code - #
  # ------------------------------------------------ #

  # Used for e.g. chapter titles, "now playing".
  # x_/y_origin: shows where in the image x and y should refer to.
  # 0,0 = center, -1/-1 = top left, -1/1 = bottom left, etc
  def show_text_sprite(proc_tag, x, y, x_origin = 0, y_origin = 0, slot = 2)
    self << %(lsph #{slot}, #{proc_tag}, #{x}, #{y})
    self << "getspsize #{slot}, %i1, %i2"
    self << %(lsp2 #{slot}, #{proc_tag}, (#{x}) + (#{-x_origin}) * (%i1 / 2), (#{y}) + (#{-y_origin}) * (%i2 / 2), 100, 100, 0, 255)
    self << "print 2"
  end

  # --------------------------------------- #
  # - methods for individual instructions - #
  # --------------------------------------- #

  def dialogue(num, var1, length, str)
    debug "DIALOGUE: line #{num}, var1 #{var1}"
    debug "raw: #{str}"
    components = str.split(/(?=@.)/)

    character_name = nil
    result_str = ""
    furi1, furi2 = nil, nil

    components.each do |e|
      if e.start_with? '@'
        tag, content = [e[0..1], e[2..-1]]
        case tag
        when "@k" # click wait
          result_str += "@#{content}"
        when "@r" # newline
          result_str += "\n^#{content}"
        when "@v" # play voice
          # TODO: support for multiple simultaneous voices, like:
          # @r@o70.@v10/10100255|13/10400165.「「うーうーうーうー！！！」」
          voice_name, text = content.split(".")
          result_str += %(/\nwave "voice/#{voice_name}.wav"\n^#{text})
        when "@b" # begin furigana
          furi1 = content[0..-2] # remove trailing period
        when "@<" # begin what the furigana refers to
          furi2 = content
        when "@>" # end furigana
          # TODO: find a way to actually display furigana (or other ruby text)
          # in Ponscripter. It does not have the ruby text support of other
          # NScripter-type engines, so it is not possible natively. An old
          # (supposedly outdated) manual file reads:
          #
          #   Both [ruby and tategaki] can be simulated in small
          #   quantities if required by judicious use of h_textextent and font
          #   size/position tags.
          #
          # Using h_textextent to measure the text for correct centering of the
          # ruby text makes sense, but I cannot figure out how to use the result
          # within position tags, or even how to interpolate variables into
          # text formatting tags in general.
          # For now, use parentheses instead.
          result_str += "#{furi2}(#{furi1})#{content}"
        when "@["
          # This probably denotes a formatting region. It remains to be seen
          # whether parsing this is actually relevant for any format tag
          result_str += "[#{content}"
        when "@]" # End region
          result_str += "]#{content}"
        when "@|" # defines pipe to be waited for. NYI
          result_str += "#{content}"
        when "@y" # after the pipe wait is finished. NYI
          result_str += "#{content}"
        when "@w" # waiting for a specified amount of time?
          result_str += "/\n; wait #{content}\n^"
        when "@o" # Maybe sets voice volume?
          # Frequently used when multiple voices are playing, and the value is
          # usually lower the more voices are playing at once.
        when "@a" # Possibly sets text speed/fade in mode?
        when "@z" # Font size in percent
          percent_size, text = content.split(".")
          result_str += "~%#{percent_size}~#{text}"
        when "@s" # Sets display speed of individual characters
          # If used as @s0., it probably sets each character to be displayed individually?
        when "@{" # Start of bold text
        when "@}" # End of bold text
        when "@e" # Perhaps prevents fast-forward mode or something?
        when "@c" # Coloured text
          colour, text = content.split(".")

          if colour.nil? || colour.empty?
            result_str += "#ffffff" # Reset colour
          else
            puts "colour: #{colour}"
            # The colour is represented as three digits like "279", where each
            # digit represents one channel from 0-9. So 999 would be #ffffff
            red, green, blue = colour.chars.map(&:to_i).map { |e| e * 255 / 9 }
            colour_num = (red << 16) | (green << 8) | (blue)
            hex_colour = '#' + colour_num.to_s(16).rjust(6, '0')
            result_str += hex_colour
          end
        when "@t" # Delineates two simultaneously appearing lines
        when "@-" # No idea what this means, only used in Umineko extra content
        else
          raise "Unrecognised dialogue tag: #{tag}"
        end
      else
        character_name = e
      end
    end

    result_str.strip!
    result_str.gsub!('�', '　')

    if character_name.nil?
      self << "set_nochar"
    else
      self << "set_char"
      # TODO: find out how to display this above the text window
      self << %(lsp2 slot_char_name, ":s/40,40,0,0;#ffffff#{character_name}", %char_name_x, %char_name_y, 100, 100, 0)
    end
    self << "#{result_str}@" # actual line
    @dialogue_lines << result_str
    self << "csp2 slot_char_name:textclear:wavestop"
    newline
  end

  def ins_0x87(argument)
    nyi
    debug "instruction 0x87 (dialogue pipe wait?), argument: #{hex(argument)}"
  end

  def ins_0x88
    nyi
    debug "instruction 0x88"
  end

  def ins_0x89(argument, val1)
    nyi
    debug "instruction 0x89 (hide dialogue window?), argument: #{hex(argument)}, val1: #{val1}"
  end

  def ins_0x8a(argument)
    nyi
    debug "instruction 0x8a, argument: #{hex(argument)}"
  end

  def ins_0x8b(data)
    nyi
    debug "instruction 0x8b, argument: #{hex(data)}"
  end

  def ins_0x8d(val1, val2, register, val3, code, data)
    debug "instruction 0x8d, val1: #{hex(val1)}, val2: #{hex(val2)}, register: #{hex(register)}, val3: #{val3}, code: '#{code}', data: '#{data}'"

    if code == "NCSELECT"
      ncselect(data.split("\x00").compact)
    else
      nyi
    end
  end

  def perform_transition_1(val1, val2, val3, length_byte, data)
    debug "perform transition (type 1, 0x8e), val1: #{val1}, val2: #{val2}, val3: #{val3}, length_byte: 0b#{length_byte.to_s(2)}, data: #{data}"
    self << "print 2"
  end

  def perform_transition_2(val1, val2, val3, length_byte, data)
    nyi
    debug "perform transition (kal-type/type 2, 0xc9), val1: #{val1}, val2: #{val2}, val3: #{val3}, length_byte: 0b#{length_byte.to_s(2)}, data: #{data}"
  end

  def ins_0x8f
    nyi
    debug "instruction 0x8f"
  end

  # Register stuff

  def register_signed_assign(reg, value)
    self << "mov #{register(reg)}, #{nscify(value)} ; #{value}"
  end

  def register_unsigned_assign(reg, value)
    self << "mov #{register(reg)}, #{nscify(value)} ;unsigned #{value}"
  end

  def register_add(reg, value)
    self << "mov #{register(reg)}, #{register(reg)} + #{nscify(value)} ; #{value}"
  end

  def register_sub(reg, value)
    self << "mov #{register(reg)}, #{register(reg)} - #{nscify(value)} ; #{value}"
  end

  def register_mul(reg, value)
    self << "mov #{register(reg)}, #{register(reg)} * #{nscify(value)} ; #{value}"
  end

  def register_div(reg, value)
    self << "mov #{register(reg)}, #{register(reg)} / #{nscify(value)} ; #{value}"
  end

  def register_and(reg, value)
    nyi
    debug "mov #{register(reg)}, #{register(reg)} & #{value}"
  end

  def register_0x08(reg, value)
    # something special to kaleido. (Couldn't find this in saku)
    # The second argument appears to always be a power of 2, or 0.
    # I have a hunch that it might actually be logical or, so I'm implementing
    # this as + for now.
    self << "mov #{register(reg)}, #{register(reg)} + #{nscify(value)} ; #{value}"
  end

  def register_add2(reg, value1, value2)
    self << "mov #{register(reg)}, #{nscify(value1)} + #{nscify(value2)} ; #{value1} #{value2}"
  end

  def register_sub2(reg, value1, value2)
    self << "mov #{register(reg)}, #{nscify(value1)} - #{nscify(value2)} ; #{value1} #{value2}"
  end

  def register_0x84(reg, value1, value2)
    nyi
    debug "mov #{register(reg)}, #{register(reg)} [0x84] #{value1} #{value2} ; potentially two argument multiplication?"
  end

  def register_0x85(reg, value1, value2)
    nyi
    debug "mov #{register(reg)}, #{register(reg)} [0x85] #{value1} #{value2} ; potentially two argument division?"
  end

  def register_0x86(reg, value1, value2)
    nyi
    debug "mov #{register(reg)}, #{register(reg)} [0x86] #{value1} #{value2} ; potentially two argument or?"
  end

  def register_0x87(reg, value1, value2)
    nyi
    debug "mov #{register(reg)}, #{value1} [0x87] #{value2} ; potentially two argument and?"
  end

  # Other register stuff

  def ins_0x40(val1, val2, val3)
    nyi
    debug "instruction 0x40, val1: #{val1}, val2: #{val2}, val3: #{val3}"
  end

  # The SNR file uses a stack-based operation language for complex calculations.
  # This class represents one of those operations being parsed and converted to
  # NSC.
  class CalcStack
    def initialize
      @stack = []
      @result = []
    end

    def push(val)
      @stack.push(val)
    end

    def pop
      @stack.pop
    end

    def raw_stack
      @stack
    end

    # A simple binary operation that can be expressed with a single operator in nsc.
    def simple_binary(operator)
      second = @stack.pop
      @stack.push(['(', @stack.pop, " #{operator} ", second, ')'])
    end

    # A simple unary operation that can be expressed with a single operator in nsc.
    def simple_unary(operator)
      @stack.push(["(#{operator} ", @stack.pop, ')'])
    end

    # Stores the calculation up to the current point in %i1, so a more complex
    # calculation can be performed in the meantime. The calculation will be
    # resumed with %i2.
    def intermediate
      @result << "mov %i1, #{nested_array_to_nsc(@stack.pop)} ; calc intermediate"
      push('%i1')
      yield
      push('%i2')
    end

    def finalize(register)
      @result << "mov #{register}, #{nested_array_to_nsc(@stack.pop)} ; calc final"
      @result.join("\n")
    end

    def <<(line)
      @result << line
    end

    def empty?
      @stack.empty?
    end

    def nested_array_to_nsc(nested)
      raise 'nested is nil' if nested.nil?
      [nested].flatten.join
    end
  end

  def calc(target, operations)
    stack = CalcStack.new

    operations.each do |op, val|
      case op
      when 0x00 # push
        stack.push(nscify(val))
      when 0x01
        stack.simple_binary('+')
      when 0x02
        stack.simple_binary('-')
      when 0x03
        stack.simple_binary('*')
      when 0x04
        stack.simple_binary('/')
      when 0x0b
        nyi
        stack.simple_unary('[0x0b]')
      when 0x10 # probably: 0 if to_check < to_compare, 1 if to_check >= to_compare
        stack.intermediate do
          to_compare = stack.pop
          to_check = stack.pop
          stack << "if #{to_check} < #{to_compare}: mov %i2, 0"
          stack << "if #{to_check} >= #{to_compare}: mov %i2, 1"
        end
      when 0x18 # ternary operator? to_check ? true_val : false_val
        stack.intermediate do
          to_check = stack.pop
          true_val = stack.pop
          false_val = stack.pop
          stack << "if #{to_check} > 0: mov %i2, #{true_val}"
          stack << "if #{to_check} <= 0: mov %i2, #{false_val}"
        end
      else
        nyi
        stack.simple_binary("[0x#{op.to_s(16)}]")
      end
    end

    self << stack.finalize(register(target))

    unless stack.empty?
      nyi
      debug "Could not fully parse expression! Stack at the end: #{stack.raw_stack}"
    end
    #self << "mov #{register(target)}, #{stack.flatten.join} ; calc #{operations.map { |e| e.length == 2 ? [hex(e.first), e.last.to_s] : [hex(e.first)] }.join(' ')}"
  end

  def store_in_multiple_registers(value, registers)
    self << registers.map.with_index { |e, i| "mov #{register(e)}, #{nscify(value)}" }.join(':') + " ; #{value}"
  end

  # Read values[index] to target
  def lookup_read(target, index, values)
    self << "movz ?lookup, #{values.map { |e| nscify(e) }.join(', ')} ; #{values.map(&:to_s)} ; lookup_read"
    self << "mov #{register(target)}, ?lookup[#{nscify(index)}] ; #{index}"
  end

  # Store the given value in the register determined by registers[index]
  def lookup_store(value, index, registers)
    self << "movz ?lookup, #{registers.map { |e| register(e) }.join(', ')} ; lookup_store"
    self << "mov ?lookup[#{nscify(index)}], #{nscify(value)} ; value: #{value}, index: #{index}"
    self << registers.map.with_index { |e, i| "mov #{register(e)}, ?lookup[#{i}]" }.join(':')
  end

  # Control flow

  def call(addr, data)
    self << "#{address(addr)} #{data.map { |e| nscify(e) }.join(', ')} ; #{data.map(&:to_s).join(', ')}"
    unless @known_functions.include?(addr)
      @h[1] << "defsub #{address(addr)}"
      lines_at_func = (@h[addr] ||= [])
      lines_before = []

      # Save parameter values that might be overwritten to the pstack
      data.each_with_index do |_, i|
        lines_before << "inc %psp:mov ?param_stack[%psp], #{parameter(i)}"
      end
      lines_before << "inc %psp:mov ?param_stack[%psp], #{data.length}"
      # lines_before << "^call0x#{addr.to_s(16)},^%psp^,^#{data.length}^-^?param_stack[%psp]^/"
      if data.length > 0
        # Load new parameter into variable
        lines_before << "getparam " + data.map.with_index { |_, i| parameter(i) }.join(", ")
      end
      lines_at_func.unshift(lines_before)
      @known_functions << addr
    end
  end

  def unconditional_jump(addr)
    p addr
    self << "goto *#{address(addr)}"
  end

  def conditional_jump(val1, val2, addr, comparison)
    self << "if #{nscify(val1)} #{comparison} #{nscify(val2)} goto *#{address(addr)} ; #{val1} #{val2}"
  end

  def conditional_jump_equal(val1, val2, addr)
    conditional_jump(val1, val2, addr, "==")
  end

  def conditional_jump_inequal(val1, val2, addr)
    conditional_jump(val1, val2, addr, "!=")
  end

  def conditional_jump_greater_or_equal(val1, val2, addr)
    conditional_jump(val1, val2, addr, ">=")
  end

  def conditional_jump_greater_than(val1, val2, addr)
    conditional_jump(val1, val2, addr, ">")
  end

  def conditional_jump_less_or_equal(val1, val2, addr)
    conditional_jump(val1, val2, addr, "<=")
  end

  def conditional_jump_less_than(val1, val2, addr)
    conditional_jump(val1, val2, addr, "<")
  end

  def conditional_jump_0x06(val1, val2, addr) # conjecture: checks whether bit is set
    # Ponscripter does not support logical operations, so we have to do this using division...
    self << "if (#{nscify(val1)} / #{nscify(val2)}) mod 2 == 1 goto *#{address(addr)} ; #{val1} #{val2}"
  end

  def conditional_jump_0x86(val1, val2, addr) # MAYBE checks whether a bit is not set? this could mean that [0x8X] = ![0x0X]
    # nyi; conditional_jump(val1, val2, addr, "[0x86]")
    self << "if (#{nscify(val1)} / #{nscify(val2)}) mod 2 == 0 goto *#{address(addr)} ; #{val1} #{val2}"
  end

  def ins_0x48(addr)
    nyi
    debug "instruction 0x48 (gosub?), addr: #{address(addr)}"
  end

  def ins_0x49
    nyi
    debug "instruction 0x49 (return?)"
  end

  def table_goto(value, targets)
    self << "tablegoto #{nscify(value)}, #{addresses(targets).join(', ')} ; #{value}"
  end

  def ins_0x4b(register, targets)
    nyi
    debug "instruction 0x4b, register: #{hex(register)}, targets: #{addresses(targets)}"
  end

  def ins_0x4c(data)
    nyi
    debug "instruction 0x4c, data: #{hex(data)}"
  end

  def return
    #self << "^return_at 0x#{@offset.to_s(16)}/"
    self << "restore_params:return ;0x#{@offset.to_s(16)}"
    newline
  end

  def ins_0x51(reg, val3, val4, data) # conjecture: matching something to a set of values?
    if val4.value != 0
      puts "invalid val4 #{hex(val4)}"
      exit
    end
    self << "mov %i1, null ; 0x51 val3: #{val3}"
    data.each_with_index do |e, i|
      self << "if #{nscify(val3)} == #{e}: mov %i1, #{i}"
    end
    self << "mov #{register(reg)}, %i1"
  end

  def ins_0x52
    nyi
    debug "instruction 0x52 (some kind of return?)"
  end

  def ins_0x53(reg, val1, val2)
  debug "instruction 0x53: register: #{hex(reg)}, val1: #{val1}, val2: #{val2}"
  end

  def end
    nyi
    debug "end"
  end

  def ins_0x80(reg, val1)
    nyi
    debug "instruction 0x80: register: #{hex(reg)}, val1: #{val1}"
  end

  def ins_0x81(register, val1)
    nyi
    debug "instruction 0x81: register: #{hex(register)}, val1: #{val1}"
  end

  def ins_0x82(data)
    nyi
    debug "instruction 0x82: #{hex(data)}"
  end

  def wait_frames(mode, num_frames)
    debug "wait frames (0x83): mode #{mode}"
    self << "mov %i1, #{nscify(num_frames)} * 16 ; wait #{num_frames} frames" # TOOD: more accurate timing
    self << "wait %i1"
  end

  # Most likely sets the current textbox mode. (ADV/NVL, or special positions maybe?)
  def set_text_positioning_mode(mode)
    # The 0x20 (32) bit seems to have some particular significance here.
    self << "lookup_window #{nscify(mode)} ; #{mode}"
    self << "set_nochar"
  end

  # Stack related?

  def stack_push(values)
    values.each do |value|
      self << "inc %sp:mov ?stack[%sp], #{nscify(value)} ; push #{value}"
    end
  end

  def stack_pop(values)
    values.each do |value|
      self << "mov #{register(value)}, ?stack[%sp]:dec %sp ; pop #{hex(value)}"
    end
  end

  def ins_0xff(code, arguments) # most likely an external/internal call
    debug "instruction 0xff (internal call) at 0x#{@offset.to_s(16)}, code: '#{code}', arguments: #{arguments.map(&:to_s).join(', ')}"
    if FF_CALLS.key? code
      self << "#{FF_CALLS[code]} #{arguments.map { |e| nscify(e) }.join(', ')}"
    else
      nyi
      self << %(#{code} #{arguments.map { |e| nscify(e) }.join(', ')})
    end
  end

  # An internal selection operation. Sets %r1 to the index of the selected item.
  # In production use, it will always return the last index (?)
  def ncselect(options)
    debug "NCSELECT #{options.join(', ')}"
    if SNR_PROD
      self << "mov #{register(1)}, #{options.length - 1}"
    else
      first_sprite, x, y = 10, 50, 50
      # self << %(lsp #{first_sprite - 1}, ":s/30,30,0,0;#ffffffNCSELECT", #{x}, #{y})
      options.each_with_index do |option, i|
        self << %(lsp #{first_sprite + i}, ":s/30,30,0,0;#aaffff#ffffaa#{option}", #{x}, #{y + 30 * i})
        self << %(spbtn #{first_sprite + i}, #{i + 1})
      end
      self << "btnwait %i1"
      self << options.map.with_index { |_, i| "csp #{first_sprite + i}" }.join(':')
      self << "mov #{register(1)}, %i1 - 1"
    end
  end

  # Sprites, resources

  def resource_command_0x0(slot, val1, val2)
    # The values, what do they mean?

    debug "resource command (0xc1) 0x0 (remove slot?), slot #{slot}, values: #{val1} #{val2}"
    self << "csp2 #{nscify_slot(slot)}"
  end

  def resource_command_0x1(slot, val1, val2, val3, val4, val5, width, height)
    nyi
    debug "resource command (0xc1) 0x1 (load simple?), slot #{slot}, values: #{val1} #{val2} #{val3} #{val4} #{val5} width: #{width} height: #{height}"
  end

  def load_background_0x0(slot, val1)
    debug "resource command (0xc1) 0x2 (load background) mode 0x0, slot #{slot}, val1: #{val1}"
  end

  def load_background_0x1(slot, val1, picture_index)
    debug "resource command (0xc1) 0x2 (load background) mode 0x1, slot #{slot}, val1: #{val1}, picture index: #{picture_index}"

    self << "#{LookupTable.for("background")} #{nscify(picture_index)}"
    self << "enter_lsp #{nscify_slot(slot)}, $i2, %pic_origin_x, %pic_origin_y, 0, 0, 100"
    self << "print 2"
  end

  def load_background_0x3(slot, val1, picture_index, val3)
    debug "resource command (0xc1) 0x2 (load background) mode 0x3, slot #{slot}, val1: #{val1}, picture index: #{picture_index}, val3: #{val3}"

    self << "#{LookupTable.for("background")} #{nscify(picture_index)}"
    self << "enter_lsp #{nscify_slot(slot)}, $i2, %pic_origin_x, %pic_origin_y, 0, 0, 100"
    self << "print 2"
  end

  def load_sprite(slot, val1, mode, sprite_index, val4, face_id, val6)
    debug "resource command (0xc1) 0x3 (load bustup sprite), slot #{slot}, values: #{val1} #{mode} #{sprite_index} val4: #{val4}, face_id: #{face_id}, val6: #{val6}"

    case mode
    when 0x00 # sometimes used in saku
      self << "^load sprite slot=^#{nscify(slot)}^ val1=^#{nscify(val1)}^ mode=^#{mode}}"
    when 0x01 # saku default
      self << "#{LookupTable.for("bustup")} #{nscify(sprite_index)}"
      self << %(enter_lsp #{nscify_slot(slot)}, c_sprite_folder + "/" + $i2 + "_" + $i3 + "_1.png", %bup_origin_x, %bup_origin_y, %bup_offset_x, %bup_offset_y, %bup_scale)
      self << "print 2"
    when 0x0f # kal default
      self << "#{LookupTable.for("bustup")} #{nscify(sprite_index)}"
      self << "itoa_pad $i3, #{nscify(face_id)}, 3"
      self << %(enter_lsp #{nscify_slot(slot)}, c_sprite_folder + "/" + $i2 + "_" + $i3 + ".png", %bup_origin_x, %bup_origin_y, %bup_offset_x, %bup_offset_y, %bup_scale)
      self << "print 2"
    else
      self << "^load sprite slot=^#{nscify(slot)}^ val1=^#{nscify(val1)}^ mode=^#{mode}^ sprite_index=^#{nscify(sprite_index)}}"
    end
  end

  def resource_command_0x4(slot, val1, val2)
    nyi
    debug "resource command (0xc1) 0x4 (anime_load?), slot #{slot}, values: #{val1} #{val2}"
  end

  def resource_command_0x6_0x1(slot, val1, data)
    nyi
    debug "resource command (0xc1) 0x6 0x2, slot #{slot}, values: #{val1}, data: #{data}"
  end

  def resource_command_0x6_0x2(slot, val1, data)
    nyi
    debug "resource command (0xc1) 0x6 0x2, slot #{slot}, values: #{val1}, data: #{data}"
  end

  def play_movie(slot, val1, movie_id, data)
    # data is often 1000, maybe a fadein?
    debug "Play movie, slot: #{slot}, val1: #{val1}, movie: #{movie_id}, data: #{data}"
    self << "#{LookupTable.for("movie")} #{nscify(movie_id)}"
    self << %(movie c_movie_folder + "/" + $i2 + ".mpg", click)
  end

  def resource_command_0x6_0x5(slot, val1, val3, data)
    nyi
    debug "resource command (0xc1) 0x6 0x5, slot #{slot}, values: #{val1} #{val3}, data: #{data}"
  end

  def resource_command_0x8(slot, val1, val2, val3, val4)
    nyi
    debug "resource command (0xc1) 0x8, slot #{slot}, values: #{val1} #{val2} #{val3} val4: #{val4}"
  end

  def resource_command_0x9(slot, val1, val2, val3)
    nyi
    debug "resource command (0xc1) 0x9 (special?), slot #{slot}, values: #{val1} #{val2} #{val3}"
  end

  def sprite_command_hide(slot)
    self << "csp2 #{nscify_slot(slot)}"
  end

  def sprite_command_0x01(slot)
    nyi
    debug "sprite command (0xc2) 0x01 (alpha?)"
  end

  def sprite_command_0x12(slot)
    nyi
    debug "sprite command (0xc2) 0x12 (y resize?)"
  end

  def sprite_wait_0x00(slot, val2)
    nyi
    #@h[@offset] << "^spritewait 0x00 slot=^#{nscify(slot)}^,val2=^#{nscify(val2)}"
    debug "sprite wait (0xc3) 0x00, values: #{slot} #{val2}"
  end

  def sprite_set_basic_transform(slot, target, value, delegate = false) # used frequently in saku
    debug "sprite set basic transform, slot: #{slot}, target: #{target}, value: #{value}" unless delegate

    # Special handling in the future
    case target.value!
    when 0x00 # X position?
    when 0x01 # Y position?
    when 0x02 # empirically visibility: 0 = invisible, other values = visible
    when 0x03 # empirically also X position
    when 0x04 # empirically also Y position
    when 0x05 # most likely Z position, which is not really supported as is in ponscripter.
      # IDEA of how to support this and also get around certain other snr
      # ideosyncrasies regarding sprite slots: have an automatically maintained
      # mapping of SNR sprite slots -> NSC extended sprite slots, where sprites
      # can be moved around to change their Z index. This would be quite a clean
      # solution but has the disadvantage of requiring implementations of
      # complex data structures entirely within NSC...
    when 0x06 # empirically red channel, 1000 = normal
    when 0x07 # empirically green channel, 1000 = normal
    when 0x08 # empirically blue channel, 1000 = normal
    when 0x09 # empirically alpha channel, 1000 = normal
    when 0x0a # no empirical effect determined yet
    when 0x0b # no empirical effect determined yet
    when 0x0c # X scaling, 1000 = normal
    when 0x0d # Y scaling, 1000 = normal
    when 0x0e # empirically also X scaling, 1000 = normal
    when 0x0f # empirically also Y scaling, 1000 = normal
    when 0x10 # no empirical effect determined yet
    when 0x11 # no empirical effect determined yet
    when 0x12 # empirically rotation: 0 = 0°, 500 = 180°, 1000 = 360°
    when 0x13 # empirically also rotation: 0 = 0°, 500 = 180°, 1000 = 360°
    when 0x14 # empirically X position but in the other direction
    when 0x15 # empirically Y position but in the other direction
    when 0x16 # empirically also visibility, 0 = invisible
    when 0x17 # has an empirical effect but I don't know what exactly. 2 turns the sprite invisible
    when 0x18 # various empirical effects
      # 0 = normal
      # 1 = monochrome
      # 2 = white silhouette
      # 3 = ??
      # 4 = inverted
      # 5-7 = ??
      # 8 = no effect
    when 0x19 # no empirical effect
    when 0x1a # I am not sure about this one.
      # Empirically, in Kal, it is responsible for flipping the sprite:
      # 0 = normal
      # 1 = flipped horizontally
      # 2 = flipped vertically
      # 4 = no visible effect
      # However, in Saku it appears to be used to turn a sprite monochrome
      self << "; monochrome sprite"
    when 0x1b # no empirical effect
    when 0x1c # no empirical effect. Saku's code suggests 1000 is a "normal" value
    when 0x1d # no empirical effect. Saku's code suggests 1000 is a "normal" value
    when 0x1e # no empirical effect. Saku's code suggests 1000 is a "normal" value
    when 0x1f # no empirical effect. Saku's code suggests 1000 is a "normal" value
    when 0x20 # no empirical effect
    else
      nyi
    end

    self << %(mov ?#{20 + target.value!}[#{nscify_slot(slot)}], #{nscify(value)})
    self << %(enter_msp #{nscify_slot(slot)})
    self << "print 2"
  end

  def sprite_wait_0x02(slot, val2, val3)
    nyi
    #@h[@offset] << "^spritewait 0x02 slot=^#{nscify(slot)}^,val2=^#{nscify(val2)}^,val3=^#{nscify(val3)}"
    debug "sprite wait (0xc3) 0x02, values: #{slot} #{val2} #{val3}"
  end

  def sprite_wait_0x03(slot, val2, val3, val4)
    nyi
    #@h[@offset] << "^spritewait 0x03 slot=^#{nscify(slot)}^,val2=^#{nscify(val2)}^,val3=^#{nscify(val3)}^,val4=^#{nscify(val4)}"
    debug "sprite wait (0xc3) 0x03, values: #{slot} #{val2} #{val3} #{val4}"
  end

  def sprite_wait_0x04(slot, val2, val3)
    nyi
    #@h[@offset] << "^spritewait 0x04 slot=^#{nscify(slot)}^,val2=^#{nscify(val2)}^,val3=^#{nscify(val3)}"
    debug "sprite wait (0xc3) 0x04, values: #{slot} #{val2} #{val3}"
  end

  def sprite_wait_0x05(slot, val2, val3, val4)
    nyi
    #@h[@offset] << "^spritewait 0x05 slot=^#{nscify(slot)}^,val2=^#{nscify(val2)}^,val3=^#{nscify(val3)}^,val4=^#{nscify(val4)}"
    debug "sprite wait (0xc3) 0x05 (x pos?), values: #{slot} #{val2} #{val3} #{val4}"
  end

  def sprite_wait_0x06(slot, val2, val3, val4)
    nyi
    #@h[@offset] << "^spritewait 0x06 slot=^#{nscify(slot)}^,val2=^#{nscify(val2)}^,val3=^#{nscify(val3)}^,val4=^#{nscify(val4)}"
    debug "sprite wait (0xc3) 0x06 (y pos?), values: #{slot} #{val2} #{val3} #{val4}"
  end

  def sprite_wait_0x07(slot, val2, val3, val4, val5)
    nyi
    #@h[@offset] << "^spritewait 0x07 slot=^#{nscify(slot)}^,val2=^#{nscify(val2)}^,val3=^#{nscify(val3)}^,val4=^#{nscify(val4)}^,val5=^#{nscify(val5)}"
    debug "sprite wait (0xc3) 0x07, values: #{slot} #{val2} #{val3} #{val4} #{val5}"
  end

  def sprite_set_complex_transform(slot, target, value, duration, val5, val6) # used often in kal, probably for its animation-like effects
    debug "sprite set complex transform, slot: #{slot}, target: #{target}, value: #{value}, duration: #{duration}, val5: #{val5}, val6: #{val6}. DELEGATING TO BASIC TRANSFORM"

    # Ponscripter does not natively support animations like this. So for now
    # we are not going to implement them. Perhaps in the future something like
    # setting one of the values continuously over some timespan could be done.
    sprite_set_basic_transform(slot, target, value, true)
  end

  def ins_0xc0(slot)
    nyi
    debug "instruction 0xc0, slot: #{hex(slot)}"
  end

  def ins_0xc4(target, data)
    nyi
    debug "instruction 0xc0, target: #{target}, data: #{data}"
  end

  def ins_0xc5(id1)
    nyi
    debug "instruction 0xc5 (set current slot?), id: #{id1}"
  end

  # WILD GUESS: this sets the value of the 0x7a (-6) sprite slot? unclear
  # what the second ID is for though
  def ins_0xc6(id1, id2)
    debug "instruction 0xc6 (set current slot?), id1: #{id1}, id2: #{id2}"
    self << "mov %current_slot, #{nscify(id1)}"
  end

  def ins_0xc7(slot, command)
    nyi
    debug "instruction 0xc7 (some sprite command?), slot: #{slot}, command: #{hex(command)}"
  end

  def ins_0xca(register)
    nyi
    debug "instruction 0xca, slot/register: #{hex(register)}"
  end

  def ins_0xcb
    nyi
    debug "instruction 0xcb (waiting for something?)"
  end

  def ins_0xcc(val1)
    nyi
    debug "instruction 0xcc, val1: #{hex(val1)}"
  end

  def ins_0xcd
    nyi
    debug "instruction 0xcd"
  end

  def ins_0xce(val1, val2, val3)
    nyi
    debug "instruction 0xce, val1: #{val1}, val2: #{val2}, val3: #{val3}"
  end

  # Sound related

  def play_bgm(bgm_id, fadein_frames, loop_flag, volume)
    # loop_flag is conjectured; it is always 0 in Kal
    debug "Play BGM, bgm_id: #{bgm_id}, fadein_frames: #{fadein_frames}, loop_flag: #{loop_flag}, volume: #{volume}"
    self << %(bgmvol #{nscify(volume)})
    self << "#{LookupTable.for("bgm")} #{nscify(bgm_id)}"
    self << %(bgm c_bgm_folder + "/" + $i2 + ".wav")

    show_text_sprite(%(":s/30,30,0,0;#bfffff🎵" + $i3), 5, 5, -1, -1, "slot_bgm_name")
  end

  def ins_0x91(val1)
    nyi
    debug "instruction 0x91, val1: #{val1}"
  end

  def ins_0x92(val1, val2)
    nyi
    debug "instruction 0x92, val1: #{val1}, val2: #{val2}"
  end

  def ins_0x94(val1)
    nyi
    debug "instruction 0x94, val1: #{val1}"
  end

  def play_se(channel, se_id, fadein_frames, loop_flag, volume, val4, val5)
    # loop_flag: 0 = looping, 1 = play once
    debug "Play sound effect, channel: #{channel}, se_id: #{se_id}, fadein_frames: #{fadein_frames}, loop_flag: #{loop_flag}, volume: #{volume}, val4: #{val4}, val5: #{val5}"
    # TODO: fadein
    self << "chvol 1 + #{nscify(channel)}, #{nscify(volume)}"
    self << "#{LookupTable.for("se")} #{nscify(se_id)}"
    self << %(if #{nscify(loop_flag)} > 0: dwave 1 + #{nscify(channel)}, c_se_folder + "/" + $i2 + ".wav")
    self << %(if #{nscify(loop_flag)} <= 0: dwaveloop 1 + #{nscify(channel)}, c_se_folder + "/" + $i2 + ".wav")
  end

  def fadeout_se(channel, duration)
    debug "Sound effect fadeout, channel: #{channel}, duration: #{duration}"
    self << "dwavestop 1 + #{nscify(channel)}"
  end

  def ins_0x97(channel)
    nyi
    debug "instruction 0x97 (bgm related?), channel: #{channel}"
  end

  def ins_0x98(val1, val2, val3)
    nyi
    debug "instruction 0x98, val1: #{val1}, val2: #{val2}, val3: #{val3}"
  end

  def ins_0x9a(val1, val2)
    nyi
    debug "instruction 0x9a (sound related?), val1: #{val1}, val2: #{val2}"
  end

  def ins_0x9b(val1, val2, val3, val4, val5)
    nyi
    debug "instruction 0x9b (rumble?), val1: #{val1}, val2: #{val2}, val3: #{val3}, val4: #{val4}, val5: #{val5}"
  end

  def play_voice(name, volume, val2)
    debug "play voice, name: '#{name}', volume: #{volume}, val2: #{val2}"
    self << "voicevol #{volume}"
    self << %(wave "voice/#{name}.wav")
  end

  def ins_0x9e(val1)
    nyi
    debug "instruction 0x9e (volume related?), val1: #{val1}"
  end

  def ins_0x9f(val1, val2)
    nyi
    debug "instruction 0x9f, val1: #{val1}, val2: #{val2}"
  end

  # Sections, timers

  def section_title(type, str)
    debug "section title: '#{str}', type: #{hex(type)}"
    case type
    when 0x0
      # Appears to be something internal which is not actually shown to the user.
      nyi
    when 0x1
      # Shown to the user
      show_text_sprite(%(":s/60,60,0,0;#ffffff#{str}"), 5, SCREEN_HEIGHT - 5, -1, 1, "slot_section_title")
      self << "mov %timer, 1000"
      self << "resettimer"
      @on_timer_finish = "csp2 3"
    end
  end

  def timer_wait
    self << "waittimer %timer"
    unless @on_timer_finish.nil?
      self << @on_timer_finish
      @on_timer_finish = nil
    end
  end

  def ins_0xa2(argument)
    nyi
    debug "instruction 0xa2 (clear timer & disable skip?), argument: #{hex(argument)}"
  end

  def ins_0xa3
    nyi
    debug "instruction 0xa3 (unset timer?)"
  end

  def ins_0xa6(val1, val2)
    nyi
    debug "instruction 0xa6, val1: #{val1}, val2: #{val2}"
  end

  def ins_0xb0(val)
    nyi
    debug "instruction 0xb0 (marker?), val: #{hex(val)}"
  end

  def ins_0xb1(val1, data)
    nyi
    debug "instruction 0xb1, val1: #{val1}, data: #{data}"
  end

  # Game specific instructions

  def ins_0xe0_kal(data)
    nyi
    debug "instruction 0xe0 (Kal specific), data: #{data}"
  end

  def ins_0xe0_saku(data) # related to updating the character screen
    nyi
    debug "instruction 0xe0 (Saku specific), data: #{data}"
  end

  def ins_0xe1_saku(data) # related to notes/tips
    nyi
    debug "instruction 0xe1 (Saku specific), data: #{data}"
  end

  def ins_0xe2_saku(data) # used for certain selections
    nyi
    debug "instruction 0xe2 (Saku specific), data: #{data}"
  end

  def ins_0xe3_saku(data) # most likely just opens the character screen, used only once
    nyi
    debug "instruction 0xe3 (Saku specific), data: #{data}"
  end

  def ins_0xe4_saku(data) # related to updating the character screen
    nyi
    debug "instruction 0xe4 (Saku specific), data: #{data}"
  end
end

# Instead of a Ponscripter script, this outfile format generates Ruby code that
# can be used to reconstruct the original SNR file.
class RawOutFile
  def initialize
    @h = {}
    @offset = 0
    @require_labels = Set.new
  end

  attr_reader :offset

  def entry_point=(value)
    @entry_point = value
    @require_labels << value
  end

  def offset=(value)
    @offset = value
    @h[@offset] ||= []
  end

  def <<(line)
    @h[@offset] << line
  end

  # Write the created data to the given path
  def write(path)
    file = open(path, 'w')

    # assign labels to locations used in jumps
    # combine lines to file, inserting labels
    # write to file
    @h.to_a.sort_by(&:first).each do |k, v|
      if @require_labels.include? k
        file.puts "#{@entry_point == k ? 'entry_point = ' : ''}s.label :#{raw_address(k)}"
      end
      v.each { |line| file.puts line }
    end
  end

  def label(addr)
    @require_labels << addr
    ':' + raw_address(addr)
  end

  def raw_address(num)
    "addr_0x#{num.to_s(16)}"
  end
end

# Generates a number-to-string lookup table in NScripter code. Used to access assets by their IDs.
# This is done by essentially using a really big tablegoto, with each target doing a mov and then return
# TODO: there may be a much more elegant method to do this
class LookupTable
  def initialize(name)
    @name = name
    @elements = []
    @current_index = 0
  end

  # Appends some data.
  # Data should be in the format [[$i2, "blah"], [%i3, 12345], ...]
  def append(id, data)
    raise "Invalid ID" if id != @current_index
    @elements << data
    @current_index += 1
  end

  def generate
    return "\n" if @elements.empty?
    str = StringIO.new
    str.puts "*#{LookupTable.for(@name)}"
    str.puts "getparam %i1"
    str.puts "tablegoto %i1, " + @elements.map.with_index { |e, i| "*#{entry_for(i)}" }.join(', ')
    str.puts "return"
    @elements.each_with_index do |e, i|
      str.write "*#{entry_for(i)}:"
      e.each do |target, value|
        str.write "mov #{target}, #{value}:"
      end
      str.puts "return"
    end
    str.puts
    str.string
  end

  def write_to(out)
    orig = out.offset
    out.offset = 1
    out << "defsub #{LookupTable.for(@name)}"
    out.offset = out.script_offset
    out << generate
    out.offset = orig
  end

  def self.for(name); "lt_lookup_#{name}"; end
  def entry_for(id); "lt_#{@name}_entry_#{id}"; end
end

# Load origin positions from a file. This file may be bup or pic, it remains to be
# checked if non-Kal style files work too
def read_origin(file_path)
  file = File.open(file_path, 'rb')
  file.seek(0xc)
  result = file.read(4).unpack('s<s<') # assuming these are signed
  puts "Read origin of file #{file_path}: #{result}"
  result
end

# Parse file header
magic = file.read(4)
if magic != 'SNR '
  puts "Not an SNR file!".c(91)
  exit
end

filesize, dialogue_line_count, _, _, _, _, _ = file.unpack_read('L<L<L<L<L<L<L<')
script_offset, mask_offset, bg_offset, bustup_offset, bgm_offset, se_offset, movie_offset, voice_offset, offset8, offset9 = file.unpack_read('L<L<L<L<L<L<L<L<L<L<')
offset10, characters_offset, offset12, tips_offset = file.unpack_read('L<L<L<L<') if MODE == :saku

out = OutFile.new(0x0, script_offset)
raw = RawOutFile.new
$stuff = [] # Keeps track of what has been read from the file

raw.offset = 0
raw << "def raw_apply(snr)"
raw << "snr.mode = :saku" if MODE == :saku

out.offset = 0
out.newline
out << "; Generated by Neurochitin's read_scenario.rb"
out << "; SHA256 checksum of original .snr file: #{sha256}"
out << "; Original filesize: #{filesize} bytes"
out << "; Number of dialogue lines: #{dialogue_line_count}"
out.newline

out.offset = 1
out << "; Functions"

out.offset = 2
out << "; Aliases for NScripter variables representing SNR registers"

out.offset = 3
out << "; Constants"
out << %(stralias c_bg_folder, "#{BG_FOLDER}")
out << %(stralias c_sprite_folder, "#{SPRITE_FOLDER}")
out << %(stralias c_bgm_folder, "#{BGM_FOLDER}")
out << %(stralias c_se_folder, "#{SE_FOLDER}")
out << %(stralias c_movie_folder, "#{MOVIE_FOLDER}")

# Read masks
Mask = Struct.new(:name, :offset)
file.read_table(mask_offset) do |n|
  out.offset, raw.offset = file.pos, file.pos
  len, _ = file.unpack_read(MODE == :konosuba ? 'C' : 'S<') # Konosuba appears to only use one byte for many string lengths
  name = file.read_shift_jis(len)
  out.masks[n] = Mask.new(name, file.pos)
  raw << "snr.mask '#{name}'"
  out << "; Mask 0x#{n.to_s(16)} at 0x#{file.pos.to_s(16)}: #{name}"
end
out.newline
raw << "snr.write_masks\n"

# Read backgrounds
lut = LookupTable.new("background")
Background = Struct.new(:name, :offset, :val1)
file.read_table(bg_offset) do |n|
  out.offset, raw.offset = file.pos, file.pos
  len, _ = file.unpack_read(MODE == :konosuba ? 'C' : 'S<')
  name = file.read_shift_jis(len)
  raw_name = name.clone
  name.gsub!("%TIME%", "a") if MODE == :kal # TODO: find out what's up with these %TIME% bgs
  val1, _ = file.unpack_read('S<')
  out.backgrounds[n] = Background.new(name, file.pos, val1)
  raw << "snr.bg '#{raw_name}', #{val1}"

  lut_entry = []
  lut_entry << ["$i2", out.raw_background(n)]

  bg_path = File.join(base_path, PICTURE_FOLDER, name + '.pic')
  x_origin, y_origin = File.exist?(bg_path) ? read_origin(bg_path) : [0, 0]
  lut_entry << ["%pic_origin_x", x_origin]
  lut_entry << ["%pic_origin_y", y_origin]

  lut.append(n, lut_entry)
  out << "; Background 0x#{n.to_s(16)} at 0x#{file.pos.to_s(16)}: #{name} (val1 = 0x#{val1.to_s(16)})"
  out << %(stralias #{out.raw_background(n)}, "#{File.join(BG_FOLDER, name + BG_EXT)}")
end
out.newline
raw << "snr.write_bgs\n"
lut.write_to(out)
puts "Read #{out.backgrounds.length} backgrounds"

# Read bustups
lut = LookupTable.new("bustup")

if MODE == :kal
  # In Kal, bustups only have one name, but a bunch of values at the end.
  Bustup = Struct.new(:name, :offset, :character_id, :scale_percent, :x_offset, :y_offset)
else
  # In Saku, bustups have two strings (what I assume are name and expression), and only one value at the end.
  Bustup = Struct.new(:name, :expression, :offset, :character_id)
end

file.read_table(bustup_offset) do |n|
  out.offset, raw.offset = file.pos, file.pos
  len, _ = file.unpack_read(MODE == :konosuba ? 'C' : 'S<')
  if MODE == :kal
    name = file.read_shift_jis(len)
    raw_name = name.clone
    name.gsub!("%DRESS%", "首輪") # TODO: do this in a smarter way
    character_id, scale_percent, x_offset, y_offset = file.unpack_read('S<S<S<s<')
    out.bustups[n] = Bustup.new(name, file.pos, character_id, scale_percent, x_offset, y_offset)
    raw << "snr.bustup '#{raw_name}', #{character_id}, #{scale_percent}, #{x_offset}, #{y_offset}"

    lut_entry = []
    lut_entry << ["$i2", out.raw_bustup(n)]
    lut_entry << ["%bup_offset_x", x_offset]
    lut_entry << ["%bup_offset_y", y_offset]
    lut_entry << ["%bup_scale", scale_percent]

    bup_path = File.join(base_path, BUSTUP_FOLDER, name + '.bup')
    x_origin, y_origin = File.exist?(bup_path) ? read_origin(bup_path) : [0, 0]
    lut_entry << ["%bup_origin_x", x_origin]
    lut_entry << ["%bup_origin_y", y_origin]

    lut.append(n, lut_entry)
    out << "; Bustup 0x#{n.to_s(16)} at 0x#{file.pos.to_s(16)}: #{name} (character_id = 0x#{character_id.to_s(16)}, scale_percent = 0x#{scale_percent.to_s(16)}, x_offset = 0x#{x_offset.to_s(16)}, y_offset = 0x#{y_offset.to_s(16)})"
  else
    name = file.read_shift_jis(len)
    len, _ = file.unpack_read(MODE == :konosuba ? 'C' : 'S<')
    expr = file.read_shift_jis(len)
    character_id, _ = file.unpack_read('S<')
    out.bustups[n] = Bustup.new(name, expr, file.pos, character_id)
    raw << "snr.bustup '#{name}', '#{expr}', #{character_id}"

    lut_entry = []
    lut_entry << ["$i2", out.raw_bustup(n)]
    lut_entry << ["$i3", %("#{expr}")]

    bup_path = File.join(base_path, BUSTUP_FOLDER, name + '.bup')
    x_origin, y_origin = File.exist?(bup_path) ? read_origin(bup_path) : [0, 0]
    lut_entry << ["%bup_origin_x", x_origin]
    lut_entry << ["%bup_origin_y", y_origin]

    lut.append(n, lut_entry)
    out << "; Bustup 0x#{n.to_s(16)} at 0x#{file.pos.to_s(16)}: #{name} #{expr} (character_id = 0x#{character_id.to_s(16)})"
  end
  out << %(stralias #{out.raw_bustup(n)}, "#{name}")
end
out.newline
raw << "snr.write_bustups\n"
lut.write_to(out)
puts "Read #{out.bustups.length} bustups"

# Read BGM
lut = LookupTable.new("bgm")
BGMTrack = Struct.new(:name1, :name2, :offset, :val1)
file.read_table(bgm_offset) do |n|
  out.offset, raw.offset = file.pos, file.pos
  len1, _ = file.unpack_read('S<')
  name1 = file.read_shift_jis(len1)
  len2, _ = file.unpack_read('S<')
  name2 = file.read_shift_jis(len2)
  val1, _ = file.unpack_read('S<')
  out.bgm_tracks[n] = BGMTrack.new(name1, name2, file.pos, val1)
  raw << "snr.bgm '#{name1}', %(#{name2}), #{val1}"

  lut_entry = []
  lut_entry << ["$i2", out.raw_bgm_track(n)]
  lut_entry << ["$i3", %("#{name2}")]
  lut.append(n, lut_entry)

  out << "; BGM 0x#{n.to_s(16)} at 0x#{file.pos.to_s(16)}: #{name1} #{name2} (val1 = 0x#{val1.to_s(16)})"
  out << %(stralias #{out.raw_bgm_track(n)}, "#{name1}" ; #{name2})
end
out.newline
raw << "snr.write_bgms\n"
lut.write_to(out)
puts "Read #{out.bgm_tracks.length} BGM tracks"

# Read SFX
lut = LookupTable.new("se")
SoundEffect = Struct.new(:name, :offset)
file.read_table(se_offset) do |n|
  out.offset, raw.offset = file.pos, file.pos
  len, _ = file.unpack_read(MODE == :konosuba ? 'C' : 'S<')
  name = file.read_shift_jis(len)
  out.sound_effects[n] = SoundEffect.new(name, file.pos)
  raw << "snr.se '#{name}'"
  lut.append(n, [["$i2", out.raw_sound_effect(n)]])
  out << "; Sound effect 0x#{n.to_s(16)} at 0x#{file.pos.to_s(16)}: #{name}"
  out << %(stralias #{out.raw_sound_effect(n)}, "#{name}")
end
out.newline
raw << "snr.write_ses\n"
lut.write_to(out)
puts "Read #{out.sound_effects.length} sound effects"

# Read movies
lut = LookupTable.new("movie")
Movie = Struct.new(:name, :offset, :val1, :val2, :val3)
file.read_table(movie_offset) do |n|
  out.offset, raw.offset = file.pos, file.pos
  len, _ = file.unpack_read(MODE == :konosuba ? 'C' : 'S<')
  name = file.read_shift_jis(len)
  val1, val2, val3 = file.unpack_read(MODE == :konosuba ? 'S<S<' : 'S<S<S<')
  out.movies[n] = Movie.new(name, file.pos, val1, val2, val3)
  raw << "snr.movie '#{name}', #{val1}, #{val2}, #{val3}"
  lut.append(n, [["$i2", out.raw_movie(n)]])
  out << "; Movie 0x#{n.to_s(16)} at 0x#{file.pos.to_s(16)}: #{name} (val1 = 0x#{val1.to_s(16)}, val2 = 0x#{val2.to_s(16)}, val3 = 0x#{val3&.to_s(16)})"
  out << %(stralias #{out.raw_movie(n)}, "#{name}")
end
out.newline
raw << "snr.write_movies\n"
lut.write_to(out)
puts "Read #{out.movies.length} movies"

# Read voices
Voice = Struct.new(:name, :offset, :values)
file.read_table(voice_offset) do |n|
  out.offset, raw.offset = file.pos, file.pos
  len, _ = file.unpack_read(MODE == :konosuba ? 'C' : 'S<')
  name = file.read_shift_jis(len)
  if MODE == :kal
    # Kal always has two values here.
    values = file.unpack_read('CC')
    raw << "snr.voice '#{name}', #{values[0]}, #{values[1]}"
  else
    # Saku has a number of values prefixed with their length.
    len, _ = file.unpack_read('C')
    values = file.unpack_read('C' * len)
    raw << "snr.voice '#{name}', #{len}, *#{values}"
  end
  out.voices[n] = Voice.new(name, file.pos, values)
  out << "; Voice 0x#{n.to_s(16)} at 0x#{file.pos.to_s(16)}: #{name} (values = #{values.map { |e| e.to_s(16) }.join(' ') })"
end
out.newline
raw << "snr.write_voices\n"
puts "Read #{out.voices.length} voices"

# Read ???
Table8Entry = Struct.new(:name, :offset, :data)
file.read_table(offset8, size_prefix = nil) do |n|
  out.offset, raw.offset = file.pos, file.pos
  len, _ = file.unpack_read('S<')
  name = file.read_shift_jis(len)
  len2, _ = file.unpack_read('S<')
  data = file.unpack_read('S<' * len2)
  out.table8[n] = Table8Entry.new(name, file.pos, data)
  raw << "snr.table8_entry '#{name}', #{data.join(', ')}"
  out << "; table 8 entry 0x#{n.to_s(16)} at 0x#{file.pos.to_s(16)}: #{name} (data: #{data.map { |e| e.to_s(16) } })"
end
out.newline
raw << "snr.write_table8\n"
puts "Read #{out.table8.length} table 8 entries"

# Read ?????
Table9Entry = Struct.new(:offset, :val1, :val2, :val3)
file.read_table(offset9, size_prefix = nil) do |n|
  out.offset, raw.offset = file.pos, file.pos
  val1, val2, val3 = file.unpack_read('S<S<S<')
  out.table9[n] = Table9Entry.new(file.pos, val1, val2, val3)
  raw << "snr.table9_entry #{val1}, #{val2}, #{val3}"
  out << "; table 9 entry 0x#{n.to_s(16)} at 0x#{file.pos.to_s(16)}: val1 = 0x#{val1.to_s(16)}, val2 = 0x#{val2.to_s(16)}, val3 = 0x#{val3.to_s(16)}"
end
out.newline
raw << "snr.write_table9\n"
puts "Read #{out.table9.length} table 9 entries"

# Read saku specific tables
if MODE == :saku
  # No idea what offset 10 is about. It seems to point to a blob of binary data
  # with a somewhat regular but inconsistent structure. It is certainly not
  # delimited into "elements" like previous tables are.
  file.seek(offset10)
  out.offset, raw.offset = offset10, offset10
  len, _ = file.unpack_read('L<')
  offset10_data = file.read(len)
  out.offset10_data = offset10_data
  raw << "snr.write_offset10_data #{offset10_data.unpack('C*')}"
  out << "; offset 10 data omitted, length = 0x#{len.to_s(16)}"
  out.newline
  puts "Read #{len} offset 10 data bytes"

  # Descriptions on the character screen
  CharactersEntry = Struct.new(:offset, :val1, :segments)

  CharacterSegment01 = Struct.new(:val2)
  CharacterSegment02 = Struct.new(:val3, :val4, :id1, :id2)
  CharacterSegment03 = Struct.new(:character_name, :description)

  file.read_table(characters_offset) do |n|
    out.offset, raw.offset = file.pos, file.pos

    val1, _ = file.unpack_read('C')
    segments = []

    # Read segments
    loop do
      segment_id, _ = file.unpack_read('C')
      segment = nil

      case segment_id
      when 0
        break # End of entry
      when 1
        val2, _ = file.unpack_read('C')
        segment = CharacterSegment01.new(val2)
      when 2
        val3, val4 = file.unpack_read('CC')
        id1, id2 = 2.times.map do
          len, _ = file.unpack_read('S<')
          file.read_shift_jis(len)
        end
        segment = CharacterSegment02.new(val3, val4, id1, id2)
      when 3
        character_name, description = 2.times.map do
          len, _ = file.unpack_read('S<')
          file.read_shift_jis(len)
        end
        segment = CharacterSegment03.new(character_name, description)
      else
        raise "Invalid segment ID at 0x#{file.pos.to_s(16)}: 0x#{segment_id.to_s(16)}"
      end

      segments << segment
    end

    out.characters[n] = CharactersEntry.new(file.pos, val1, segments)

    # Write to raw
    raw << "segments = []"
    segments.each do |segment|
      if segment.is_a? CharacterSegment01
        raw << "segments << [1, #{segment.val2}] \# index"
      elsif segment.is_a? CharacterSegment02
        raw << "segments << [2, #{segment.val3}, #{segment.val4}, '#{segment.id1}', '#{segment.id2}'] \# sprites?"
      elsif segment.is_a? CharacterSegment03
        raw << "segments << [3, '#{segment.character_name}', '#{segment.description}'] \# name, description"
      else
        raise "Invalid segment"
      end
    end
    raw << "snr.character #{val1}, segments"

    # Write to out
    out << "; characters entry 0x#{n.to_s(16)} at 0x#{file.pos.to_s(16)}: val1 = 0x#{val1.to_s(16)}"
    segments.each do |segment|
      out << ";   segment: #{segment}"
    end
    out << "; -- end of characters entry"
  end
  out.newline
  raw << "snr.write_characters\n"
  puts "Read #{out.characters.length} character descriptions"

  # No idea what this data is either. I *think* it is actually a table prefixed
  # with the number of elements, but I can't make out a structure in the elements
  # that would allow me to read them in one by one. Regardless, the meaning of
  # this table is a mystery to me, so there is no point in doing that anyway
  file.seek(offset12)
  out.offset, raw.offset = offset12, offset12
  len, _ = file.unpack_read('L<')
  offset12_data = file.read(len)
  out.offset12_data = offset12_data
  raw << "snr.write_offset12_data #{offset12_data.unpack('C*')}"
  out << "; offset 12 data omitted, length = 0x#{len.to_s(16)}"
  out.newline
  puts "Read #{len} offset 12 data bytes"

  # Tips in the tips screen, giving detail to the story
  # val1 is probably the episode number
  TipsEntry = Struct.new(:offset, :val1, :val2, :name, :content)
  file.read_table(tips_offset) do |n|
    out.offset, raw.offset = file.pos, file.pos
    val1, val2 = file.unpack_read('CS<')
    name, content = 2.times.map do
      len, _ = file.unpack_read('S<')
      file.read_shift_jis(len)
    end
    out.tips[n] = TipsEntry.new(file.pos, val1, val2, name, content)
    raw << "snr.tip #{val1}, #{val2}, '#{name}', '#{content}'"
    out << "; tips entry 0x#{n.to_s(16)} at 0x#{file.pos.to_s(16)}: val1 = 0x#{val1.to_s(16)}, val2 = 0x#{val2.to_s(16)}, name = '#{name}', content = '#{content}'"
  end
  out.newline
  raw << "snr.write_tips\n"
  puts "Read #{out.characters.length} tips"
end

# Text window definitions
WINDOWS.each do |_, v|
  name, value = v
  value_char, value_nochar = value
  out << %(h_defwindow "window_#{name}_char", #{value_char})
  out << %(h_defwindow "window_#{name}_nochar", #{value_nochar})
end
out.newline

# Text window lookup
orig = out.offset
out.offset = script_offset

out << "*lookup_window"
out << "getparam %i5"
WINDOWS.each do |k, v|
  name, value = v
  _, _, char_name_x, char_name_y = value
  out << %(if %i5 == #{k}:mov $window, "window_#{name}":mov %char_name_x, #{char_name_x}:mov %char_name_y, #{char_name_y}:goto *lookup_window_ret)
end
out << "^Set text positioning style ^%i5^, not yet implemented^"
out << 'mov $window, "internal_default"'
out << "*lookup_window_ret"
out << "return"
out.newline
out.offset = orig

# Parse script header
file.seek(script_offset)
out.offset = script_offset
script_magic, entry_point = file.unpack_read('L<L<')
out << "; Starting script section"
out << "; Magic: 0x#{script_magic.to_s(16)}"
out << "; Entry point: 0x#{entry_point.to_s(16)}"
out << "*snr_script_start"
out.newline

raw << "s = KalScript.new(snr.current_offset + #{RAW_SCRIPT_FIX_OFFSET})\n"
raw.entry_point = entry_point

# The loop for parsing the script data
while true do
  out.offset, raw.offset = file.pos, file.pos
  $stuff, raw_override = [], false
  begin
    instruction = file.readbyte
  rescue EOFError
    puts "Done parsing!"
    break
  end
  puts "#{(file.pos - 1).to_s(16)} Instruction: 0x#{instruction.to_s(16)}"

  case instruction
  when 0x00 # exit?
    out.end
  when 0x40 # ????
    val1, val2, val3 = file.read_variable_length(3)
    out.ins_0x40(val1, val2, val3)
  when 0x41 # Modify register (very sure about this)
    mode, register = file.unpack_read('CS<')
    data1, _ = file.read_variable_length(1)
    case mode
    when 0x00 # signed assignment?
      out.register_signed_assign(register, data1)
    when 0x01
      out.register_unsigned_assign(register, data1)
    when 0x02
      out.register_add(register, data1)
    when 0x03
      out.register_sub(register, data1)
    when 0x04 # multiplication?
      out.register_mul(register, data1)
    when 0x05
      out.register_div(register, data1)
    when 0x07
      out.register_and(register, data1)
    when 0x08 # ?
      out.register_0x08(register, data1)
    when 0x82 # two-argument addition?
      data2, _ = file.read_variable_length(1)
      out.register_add2(register, data1, data2)
    when 0x83 # two-argument subtraction (register = data1 - data2)
      data2, _ = file.read_variable_length(1)
      out.register_sub2(register, data1, data2)
    when 0x84 # ? two_argument multiplication?
      data2, _ = file.read_variable_length(1)
      out.register_0x84(register, data1, data2)
    when 0x85 # ? two_argument division?
      data2, _ = file.read_variable_length(1)
      out.register_0x85(register, data1, data2)
    when 0x86 # ?
      data2, _ = file.read_variable_length(1)
      out.register_0x86(register, data1, data2)
    when 0x87 # ?
      data2, _ = file.read_variable_length(1)
      out.register_0x87(register, data1, data2)
    else
      puts "Unknown modify register mode"
      break
    end
  when 0x42 # calculation
    target, _ = file.unpack_read('S<')
    operations = []
    loop do
      byte = file.readbyte2
      byte_print([byte], 96)
      case byte
      when 0xff
        break
      when 0x00 # push
        to_push, _ = file.read_variable_length(1)
        operations << [byte, to_push]
      else
        operations << [byte]
      end
    end

    out.calc(target, operations)
  when 0x43 # ??
    val1, _ = file.read_variable_length(1)
    length, _ = file.unpack_read('S<')
    data = file.unpack_read('S<' * length)
    out.store_in_multiple_registers(val1, data)
  when 0x44 # ??
    register, _ = file.unpack_read('S<')
    val3, _ = file.read_variable_length(1)
    len, _ = file.unpack_read('S<')
    data = []
    len.times do
      val, _ = file.read_variable_length(1)
      (4 - val.length).times { file.readbyte2 }
      data << val
    end
    # data = file.unpack_read('L<' * len)
    out.lookup_read(register, val3, data)
  when 0x45 # ??
    val1, val2 = file.read_variable_length(2)
    length, _ = file.unpack_read('S<')
    data = file.unpack_read('S<' * length)
    out.lookup_store(val1, val2, data)
  when 0x46 # conditional jump
    comparison_mode, _ = file.unpack_read('C')
    case comparison_mode
    when 0x00
      val1, val2 = file.read_variable_length(2)
      address, _ = file.unpack_read('L<', ignore = true)
      $stuff << raw.label(address)
      out.conditional_jump_equal(val1, val2, address)
    when 0x01
      val1, val2 = file.read_variable_length(2)
      address, _ = file.unpack_read('L<', ignore = true)
      $stuff << raw.label(address)
      out.conditional_jump_inequal(val1, val2, address)
    when 0x02
      val1, val2 = file.read_variable_length(2)
      address, _ = file.unpack_read('L<', ignore = true)
      $stuff << raw.label(address)
      out.conditional_jump_greater_or_equal(val1, val2, address)
    when 0x03
      val1, val2 = file.read_variable_length(2)
      address, _ = file.unpack_read('L<', ignore = true)
      $stuff << raw.label(address)
      out.conditional_jump_greater_than(val1, val2, address)
    when 0x04
      val1, val2 = file.read_variable_length(2)
      address, _ = file.unpack_read('L<', ignore = true)
      $stuff << raw.label(address)
      out.conditional_jump_less_or_equal(val1, val2, address)
    when 0x05
      val1, val2 = file.read_variable_length(2)
      address, _ = file.unpack_read('L<', ignore = true)
      $stuff << raw.label(address)
      out.conditional_jump_less_than(val1, val2, address)
    when 0x06
      val1, val2 = file.read_variable_length(2)
      address, _ = file.unpack_read('L<', ignore = true)
      $stuff << raw.label(address)
      out.conditional_jump_0x06(val1, val2, address)
    when 0x86
      val1, val2 = file.read_variable_length(2)
      address, _ = file.unpack_read('L<', ignore = true)
      $stuff << raw.label(address)
      out.conditional_jump_0x86(val1, val2, address)
    else
      puts "Unknown comparison mode"
      break
    end
  when 0x47 # jump to address unconditionally ?
    address, _ = file.unpack_read('L<', ignore = true)
    $stuff << raw.label(address)
    out.unconditional_jump(address)
  when 0x48 # gosub?
    address, _ = file.unpack_read('L<', ignore = true)
    $stuff << raw.label(address)
    out.ins_0x48(address)
  when 0x49 # return?
    out.ins_0x49
  when 0x4a # jump on value?
    value, _ = file.read_variable_length(1)
    len, _ = file.unpack_read('S<')
    targets = file.unpack_read('L<' * len, ignore = true)
    $stuff += targets.map { |e| raw.label(e) }
    out.table_goto(value, targets)
  when 0x4b # another kind of jump on value
    # register is likely related to val1 from 0x46 0x00
    register, len = file.unpack_read('CS<')
    targets = file.unpack_read('L<' * len, ignore = true)
    $stuff += targets.map { |e| raw.label(e) }
    out.ins_0x4b(register, targets)
  when 0x4c # ??
    data = file.unpack_read('CCCC')
    out.ins_0x4c(data)
  when 0x4d # maybe stack push?
    len, _ = file.unpack_read('C')
    values = file.read_variable_length(len)
    out.stack_push(values)
  when 0x4e # maybe stack pop?
    len, _ = file.unpack_read('C')
    values = file.unpack_read('S<' * len)
    out.stack_pop(values)
  when 0x4f # function call
    raw_override = true
    address, len = file.unpack_read('L<C')
    $stuff = []
    data = file.read_variable_length(len)
    raw << "s.ins 0x4f, #{raw.label(address)}, [#{$stuff.join(', ')}]"
    out.call(address, data)
  when 0x50 # return from function called with 0x4f
    out.return
  when 0x51 # matching to values?
    reg, _ = file.unpack_read('S<')
    val3, val4 = file.read_variable_length(2)
    length, _ = file.unpack_read('S<')
    data = file.unpack_read('L<' * length)
    out.ins_0x51(reg, val3, val4, data)
  when 0x52 # ?? maybe some kind of return?
    out.ins_0x52
  when 0x53 # only used in konosuba
    reg, _ = file.unpack_read('S<')
    val1, val2 = file.read_variable_length(2)
    out.ins_0x53(reg, val1, val2)
  when 0x80
    reg, _ = file.unpack_read('S<')
    val1, _ = file.read_variable_length(1)
    out.ins_0x80(reg, val1)
  when 0x81 # only used in saku, maybe "read external" (chiru)?
    register, _ = file.unpack_read('S<')
    val1, _ = file.read_variable_length(1)
    out.ins_0x81(register, val1)
  when 0x82 # ????????
    data = file.unpack_read('C' * 2)
    out.ins_0x82(data)
  when 0x83 # ??
    mode, _ = file.unpack_read('C')
    val, _ = file.read_variable_length(1)
    out.wait_frames(mode, val)
  when 0x85 # ??
    val1, _ = file.read_variable_length(1)
    out.set_text_positioning_mode(val1)
  when 0x86 # dialogue
    if MODE == :saku
      # Saku somehow stores the dialogue number in a three-byte integer??
      dialogue_num_low_bytes, dialogue_num_high_byte, var1 = file.unpack_read('S<CC')
      length, _ = file.unpack_read('S<', ignore = true)
      dialogue_num = (dialogue_num_high_byte << 16) | dialogue_num_low_bytes
    else
      dialogue_num, var1 = file.unpack_read('L<C')
      length, _ = file.unpack_read('S<', ignore = true)
    end
    str = file.read_shift_jis(length)
    out.dialogue(dialogue_num, var1, length, Utils::enter_to_readable(str))
    break if dialogue_num > max_dialogue
  when 0x87 # dialogue pipe wait
    argument, _ = file.unpack_read('C')
    puts "Not 0x7F!" if argument != 0x7f
    out.ins_0x87(argument)
  when 0x88 # only used in saku
    out.ins_0x88
  when 0x89 # hide dialogue window?
    argument, _ = file.unpack_read('C')
    puts "Not 0x00!" if argument != 0x00
    val1, _ = file.read_variable_length(1)
    out.ins_0x89(argument, val1)
  when 0x8a # ??
    argument, _ = file.unpack_read('C')
    puts "Not 0x01!" if argument != 0x01
    out.ins_0x8a(argument)
  when 0x8b # ??
    data = file.unpack_read('CCCCC')
    out.ins_0x8b(data)
  when 0x8d # some kind of internal call
    val1, val2, register = file.unpack_read('S<S<S<')
    val3, _ = file.read_variable_length(1)
    len, _ = file.unpack_read('S<', ignore = true)
    code = file.read_shift_jis(len)
    len, _ = file.unpack_read('S<', ignore = true)
    data = file.read_shift_jis(len)
    out.ins_0x8d(val1, val2, register, val3, code, data)
  when 0x8e
    val1, val2, val3 = file.read_variable_length(3)
    length_byte, _ = file.unpack_read('C')

    # Count the number of 1 bits in length_byte. Having this be the length
    # explains all instances of 0x8e I've encountered so far, but I have
    # absolutely no idea why it would be this way.
    length, lb = 0, length_byte
    while lb > 0; lb &= lb - 1; length += 1; end

    data = file.read_variable_length(length)
    out.perform_transition_1(val1, val2, val3, length_byte, data)
  when 0x8f # ??
    out.ins_0x8f
  when 0x90 # ??
    val1, val2, val3, val4 = file.read_variable_length(4)
    out.play_bgm(val1, val2, val3, val4)
  when 0x91 # ??
    val1, _ = file.read_variable_length(1)
    out.ins_0x91(val1)
  when 0x92 # ??
    val1, val2 = file.read_variable_length(2)
    out.ins_0x92(val1, val2)
  when 0x94 # only used in saku
    val1, _ = file.read_variable_length(1)
    out.ins_0x94(val1)
  when 0x95 # sfx related?
    # all of these are hypothetical...
    channel, sfxid, val1, val2, val3, val4, val5 = file.read_variable_length(7)
    out.play_se(channel, sfxid, val1, val2, val3, val4, val5)
  when 0x96 # also sfx related? some kind of fade?
    channel, _ = file.read_variable_length(1)
    var1, _ = file.read_variable_length(1)
    out.fadeout_se(channel, var1)
  when 0x97 # ?? BGM related?
    argument, _ = file.read_variable_length(1)
    out.ins_0x97(argument)
  when 0x98 # ??
    val1, val2, val3 = file.read_variable_length(3)
    out.ins_0x98(val1, val2, val3)
  when 0x9a # sound related?
    val1, val2 = file.read_variable_length(2)
    out.ins_0x9a(val1, val2)
  when 0x9b # rumble?
    val1, val2, val3, val4, val5 = file.read_variable_length(5)
    out.ins_0x9b(val1, val2, val3, val4, val5)
  when 0x9c # only used in saku, *probably* plays a voice independent from dialogue?
    len, _ = file.unpack_read('S<', ignore = true)
    str = file.read_shift_jis(len) # example of such a string: "02/10800000", which references a voice file where Krauss says "otousan! otousan!
    val1, val2 = file.read_variable_length(2) # val1 is probably a volume
    out.play_voice(str, val1, val2)
  when 0x9e # only used in saku
    argument, _ = file.read_variable_length(1)
    out.ins_0x9e(argument)
  when 0x9f # ??
    val1, val2 = file.read_variable_length(2)
    out.ins_0x9f(val1, val2)
  when 0xa0 # section title
    type, _ = file.unpack_read('C')
    length, _ = file.unpack_read('S<', ignore = true)
    str = file.read_shift_jis(length)
    out.section_title(type, str)
  when 0xa1 # set timer?
    out.timer_wait
  when 0xa2 # clear timer and disable skip??
    argument, _ = file.read_variable_length(1)
    out.ins_0xa2(argument)
  when 0xa3 # unset timer?
    out.ins_0xa3
  when 0xa6 # only used in saku
    val1, val2 = file.read_variable_length(2)
    out.ins_0xa6(val1, val2)
  when 0xb0 # section marker?
    val, _ = file.unpack_read('C')
    out.ins_0xb0(val)
  when 0xb1 # only used in saku
    val1, len = file.unpack_read('CC')
    data = file.read_variable_length(len)
    out.ins_0xb1(val1, data)
  when 0xc0
    slot, _ = file.read_variable_length(1)
    out.ins_0xc0(slot)
  when 0xc1 # resource command?
    slot, _ = file.read_variable_length(1)
    command, _ = file.unpack_read('C')
    case command
    when 0x0
      val1, val2 = file.read_variable_length(2)
      out.resource_command_0x0(slot, val1, val2)
    when 0x1 # load simple?
      val1, val2, val3, val4, val5, val6, val7 = file.read_variable_length(7)
      out.resource_command_0x1(slot, val1, val2, val3, val4, val5, val6, val7)
    when 0x2
      val1, _ = file.read_variable_length(1)
      mode, _ = file.unpack_read('C')
      case mode
      when 0x0 # only used in saku
        out.load_background_0x0(slot, val1)
      when 0x1 # used in kal most of the time
        val2, _ = file.read_variable_length(1)
        out.load_background_0x1(slot, val1, val2)
      when 0x3 # used once in kal
        val2, val3 = file.read_variable_length(2)
        out.load_background_0x3(slot, val1, val2, val3)
      else
        raise "Invalid 0xc1 0x2 mode: 0x#{mode.to_s(16)}"
      end
    when 0x3
      val1, _ = file.read_variable_length(1)
      mode, _ = file.unpack_read('C')
      if mode == 0x1
        # Appears to be a simpler mode, only used during script tests in kal.
        val3, _ = file.read_variable_length(1)
        out.load_sprite(slot, val1, mode, val3, nil, nil, nil)
      elsif mode == 0xf # The mode actually used to load sprites in kal
        val3, val4, val5, val6 = file.read_variable_length(4)
        out.load_sprite(slot, val1, mode, val3, val4, val5, val6)
      elsif mode == 0x0 # Used in saku
        out.load_sprite(slot, val1, mode, nil, nil, nil, nil)
      elsif mode == 0x3 # Used in konosuba
        val3, val4 = file.read_variable_length(2)
        out.load_sprite(slot, val1, mode, val3, val4, nil, nil)
      else
        raise "Invalid 0xc1 0x3 mode: 0x#{mode.to_s(16)}"
      end
    when 0x4
      val1, val2 = file.read_variable_length(2)
      out.resource_command_0x4(slot, val1, val2)
    when 0x6
      val1, val2 = file.unpack_read('CC')
      case val2
      when 0x01
        data, _ = file.read_variable_length(1)
        out.resource_command_0x6_0x1(slot, val1, data)
      when 0x02
        data, _ = file.read_variable_length(1)
        out.resource_command_0x6_0x2(slot, val1, data)
      when 0x03
        val3, val4 = file.read_variable_length(2)
        out.play_movie(slot, val1, val3, val4)
      when 0x05
        val3, val4 = file.read_variable_length(2)
        out.resource_command_0x6_0x5(slot, val1, val3, val4)
      else
        puts "Unknown resource command 0x06 flag"
        break
      end
    when 0x8 # only used in saku
      val1, val2, val3, val4 = file.read_variable_length(4)
      out.resource_command_0x8(slot, val1, val2, val3, val4)
    when 0x9
      val1, val2, val3 = file.read_variable_length(3)
      out.resource_command_0x9(slot, val1, val2, val3)
    else
      puts "Unknown resource command"
      break
    end
  when 0xc2 # sprite command
    slot, _ = file.read_variable_length(1)
    command, _ = file.unpack_read('C')
    case command
    when 0x00
      out.sprite_command_hide(slot)
    when 0x01
      out.sprite_command_0x01(slot)
    when 0x12
      out.sprite_command_0x12(slot)
    else
      puts "Unknown sprite command"
      break
    end
  when 0xc3 # sprite wait (pretty sure)
    val1, val2 = file.read_variable_length(2)
    property, _ = file.unpack_read('C')
    case property
    when 0x00
      out.sprite_wait_0x00(val1, val2)
    when 0x01
      val3, _ = file.read_variable_length(1)
      out.sprite_set_basic_transform(val1, val2, val3)
    when 0x02
      val3, _ = file.read_variable_length(1)
      out.sprite_wait_0x02(val1, val2, val3)
    when 0x03
      val3, val4 = file.read_variable_length(2)
      out.sprite_wait_0x03(val1, val2, val3, val4)
    when 0x04
      val3, _ = file.read_variable_length(1)
      out.sprite_wait_0x04(val1, val2, val3)
    when 0x05
      val3, val4 = file.read_variable_length(2)
      out.sprite_wait_0x05(val1, val2, val3, val4)
    when 0x06
      val3, val4 = file.read_variable_length(2)
      out.sprite_wait_0x06(val1, val2, val3, val4)
    when 0x07
      val3, val4, val5 = file.read_variable_length(3)
      out.sprite_wait_0x07(val1, val2, val3, val4, val5)
    when 0x0f # anim?
      val3, val4, val5, val6 = file.read_variable_length(4)
      out.sprite_set_complex_transform(val1, val2, val3, val4, val5, val6)
    else
      puts "Unknown sprite wait property"
      break
    end
  when 0xc4 # ?
    target, _ = file.read_variable_length(1)
    length, _ = file.unpack_read('C')
    data = file.read_variable_length(length)
    out.ins_0xc4(target, data)
  when 0xc5 # konosuba only, probably does something similar as c6 in kal
    id, _ = file.read_variable_length(1)
    out.ins_0xc5(id)
  when 0xc6 # load sprite?
    #id1, id2 = file.unpack_read('CC')
    id1, id2 = file.read_variable_length(2)
    out.ins_0xc6(id1, id2)
  when 0xc7 # sprite command
    slot, _ = file.read_variable_length(1)
    command, _ = file.unpack_read('C')
    out.ins_0xc7(slot, command)
  when 0xc9 # kal only, has exactly the same syntax as 0x8e it seems
    val1, val2, val3 = file.read_variable_length(3)
    length_byte, _ = file.unpack_read('C')

    length, lb = 0, length_byte
    while lb > 0; lb &= lb - 1; length += 1; end

    data = file.read_variable_length(length)
    out.perform_transition_2(val1, val2, val3, length_byte, data)
  when 0xca # acts upon some register or something?
    register, _ = file.unpack_read('C')
    out.ins_0xca(register)
  when 0xcb # maybe waiting for something?
    out.ins_0xcb
  when 0xcc # special
    val1, _ = file.unpack_read('C')
    out.ins_0xcc(val1)
  when 0xcd
    out.ins_0xcd
  when 0xce
    val1, val2, val3 = file.read_variable_length(3)
    out.ins_0xce(val1, val2, val3)
  when 0xe1 # saku specific
    assert_mode :saku
    len, _ = file.unpack_read('C')
    data = file.unpack_read('C' * len)
    out.ins_0xe1_saku(data)
  when 0xe2 # saku specific
    assert_mode :saku
    data = file.read_variable_length(3)
    out.ins_0xe2_saku(data)
  when 0xe3 # saku specific
    assert_mode :saku
    data = file.read_variable_length(1)
    out.ins_0xe3_saku(data)
  when 0xe4 # saku specific
    assert_mode :saku
    data = file.read_variable_length(1)
    out.ins_0xe4_saku(data)
  when 0xff # another type of internal call
    length, _ = file.unpack_read('S<', ignore = true)
    code = file.read_shift_jis(length)
    argument_length, _ = file.unpack_read('C')
    arguments = file.read_variable_length(argument_length)
    out.ins_0xff(length, arguments)
  when 0xe0 # specific
    if MODE == :kal
      data = file.read_variable_length(3)
      out.ins_0xe0_kal(data)
    else
      assert_mode :saku
      data = file.read_variable_length(2)
      out.ins_0xe0_saku(data)
    end
  else
    puts "Unknown instruction"
    break
  end

  unless raw_override
    raw << "s.ins #{(['0x' + instruction.to_s(16)] + $stuff).join(', ')}"
  end
end

raw << "snr.write_script(s.data, entry_point, s.dialogue_line_count)"
raw << "end"

puts "Writing..."

if output_path
  out.write(output_path)
  raw.write(output_path + "_raw.rb")
end

File.write(dialogue_path, out.dialogue_lines.join("\n")) if dialogue_path
