# Contains utility methods shared by the entire project.

module Utils
  # Convert data (string or array of bytes) to a hex editor-like format
  # e.g. "ABCZ" or [65, 66, 67, 90] both become "41 42 43 5a"
  def self.hexdump(data)
    data = data.bytes if data.respond_to? :bytes
    data.flatten.map { |e| e.to_s(16).rjust(2, '0') }.join(' ')
  end

  # Convert between encodings using the specified converter (should be newly
  # created), using the specified mapping to resolve unknown byte sequences.
  def self.convert_with_mappings(converter, src, mapping, mapped_encoding)
    dst = ""

    loop do
      code = converter.primitive_convert(src, dst)

      case code
      when :finished
        break
      when :invalid_byte_sequence, :undefined_conversion
        _, _, _, failed_byte_sequence, _ = converter.primitive_errinfo

        key = hexdump(failed_byte_sequence)
        mapped_char = mapping[key]
        raise "Could not convert bytes (#{code}): #{key}" if mapped_char.nil?

        converter.insert_output(mapped_char.force_encoding(mapped_encoding))
      else
        raise "Encountered unexpected error condition while converting: #{converter.primitive_errinfo}"
      end
    end

    dst
  end

  # Entergram uses halfwidth katakana instead of hiragana, probably to save a bit of space. We have to reverse this.
  # Each character in HALFWIDTH will be replaced with the corresponding one in HALFWIDTH_REPLACE
  HALFWIDTH = '｢｣ｧｨｩｪｫｬｭｮｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓﾔﾕﾖﾗﾘﾙﾚﾛﾜｦﾝｰｯ､ﾟﾞ･?｡'
  HALFWIDTH_REPLACE = '「」ぁぃぅぇぉゃゅょあいうえおかきくけこさしすせそたちつてとなにぬねのはひふへほまみむめもやゆよらりるれろわをんーっ、？！…　。　'

  # Convert a readable string to Entergram halfwidth replacement format
  def self.readable_to_enter(str)
    str.tr(HALFWIDTH, HALFWIDTH_REPLACE)
  end

  # Convert an Entergram string to a readable format
  def self.enter_to_readable(str)
    str.tr(HALFWIDTH_REPLACE, HALFWIDTH)
  end
end
