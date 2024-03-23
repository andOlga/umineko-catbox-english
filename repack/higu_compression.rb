module HiguCompression
  def self.decompress(in_bytes, count_bit_width = 4)
    marker = 1
    p = 0
    out_bytes = []

    over = 8 - count_bit_width
    count_mask = 0xff & 0xff << over # 6 => 0b11111100
    offset_mask = 0xff ^ count_mask

    while p < in_bytes.length
      # If we have exhausted the previous marker's bits, read the next marker.
      if marker == 1
        marker = 0x100 | in_bytes[p]
        p += 1
        next
      end

      if marker & 1 == 0
        # Read one byte
        b1 = in_bytes[p]
        p += 1

        out_bytes << b1
      else # marker & 1 == 1
        # Read two bytes
        b12 = in_bytes[p..p+1]
        p += 2

        b1, b2 = b12
        count = ((b1 & count_mask) >> over) + 3
        offset = ((b1 & offset_mask) << 8) | b2

        count.times do
          r = out_bytes[-(offset + 1)]
          raise "Invalid lookback offset -#{offset}" if r.nil?
          out_bytes << r
        end
      end

      marker >>= 1
    end

    out_bytes.compact
  end

  # Very naive Higu encoder that only handles run lengths, which does not make
  # much of a difference for font glyphs (which mostly consist of long-ish runs
  # of 0x00 and 0xff). Advantage: very fast and simple
  def self.compress_naive(in_bytes, count_bit_width = 4)
    max_count = (1 << count_bit_width) + 2

    # Convert in_bytes to run lengths
    run_lengths = in_bytes.each_cons(2).reduce([in_bytes.first, 1]) do |m, e|
      (e.first == e.last) ? m[0..-2] + [m.last + 1] : m + [e.last, 1]
    end

    # Convert run lengths to Higu instructions
    instructions = run_lengths.each_slice(2).map do |byte, len|
      (len < 4) ? [byte] * len : [byte, [len - 1, 0]]
    end

    # Split overlong instructions
    instruction_sets = instructions.flatten(1).map do |e|
      if e.is_a?(Array) && e.first >= max_count
        const_run = [[max_count, e.last]] * (e.first / max_count)
        last_len = e.first % max_count
        if last_len < 3 # make sure the length never goes below 3
          const_run[-1] = [const_run.last[0] - (3 - last_len), const_run.last[1]]
          last_len = 3
        end
        const_run + [[last_len, e.last]]
      else
        [e]
      end
    end

    encode_instructions(instruction_sets.flatten(1), count_bit_width)
  end

  # Encodes a set of Higu compression instructions to binary
  def self.encode_instructions(instructions, count_bit_width = 4)
    over = 8 - count_bit_width
    max_count = (1 << count_bit_width) + 2
    max_offset = (1 << over + 8) - 1

    slices = instructions.each_slice(8).map do |slice|
      marker = slice.map.with_index { |e, i| (e.is_a?(Array) ? 1 : 0) << i }.sum
      bytes = slice.map do |e|
        if e.is_a?(Array)
          count, offset = e
          raise "count too high (#{count} > #{max_count})" if count > max_count
          raise "count too low (#{count} < 3)" if count < 3
          raise "offset too high (#{offset} > #{max_offset})" if offset > max_offset
          raise "offset too low (#{offset} < 0)" if offset < 0
          b1 = ((count - 3) << over) | (offset >> 8)
          b2 = offset & 0xff
          [b1, b2]
        else
          raise "Byte out of range (#{e})" if e > 255 || e < 0
          e
        end
      end
      [marker, bytes]
    end

    slices.flatten
  end
end
