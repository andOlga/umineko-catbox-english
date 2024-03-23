# Class to layout text so that it has word-level wrapping when read on the
# Entergram engine.
class WordWrapLayouter
  attr_accessor :width

  # Creates a new layouter.
  #   The arguments should be in manifest format — a hash of numeric character
  # codepoints to `Glyph` instances; see fnt/glyph.rb.
  #   The fnt/extract.rb script generates a `manifest.rb_marshal` file that
  # can be demarshaled to obtain such a manifest object.
  #   The width is in glyph size units; it is the sum of all `frame_width`s of
  # glyph on one line. Note that character spacing in the engine is a bit
  # variable so you may get slightly different results depending on what
  # characters you use to measure this.
  #   The default value should work fine for Saku's engine; it may need
  # adjustment for Kal.
  def initialize(font_manifest_regular, font_manifest_bold = nil, width = 2970)
    @fonts = {
      regular: font_manifest_regular,

      # default to regular if bold not provided
      bold: font_manifest_bold || font_manifest_regular
    }
    @width = width
  end

  def layout(text)
    layout_run = LayoutRun.new(@fonts, @width, text)
    layout_run.layout_all
  end

  # This class handles the actual layouting, separated to avoid unnecessary
  # global state.
  class LayoutRun
    Element = Struct.new(:content, :can_break?)

    def initialize(fonts, width, text)
      @fonts = fonts
      @width = width
      @text = text

      @style = :regular
      @scale = 1.0

      @elements = []
      @current_element = ""
      @current_line_length = 0 # length of elements in @elements
                               # (WITHOUT @current_element)
      @current_element_length = 0
    end

    def char_width(char)
      @fonts[@style][char.ord].frame_width * @scale
    end

    def layout_all
      raise "Tried to reuse LayoutRun" if @done

      # The line will contain many control tags, which should obviously not be
      # taken into account directly while calculating line length, but which
      # need to be processed with special care.
      @text.split(/(?=@.)/).each do |e| # split before each control tag
        if e.start_with? '@'
          tag, content = [e[0..1], e[2..-1]]
          case tag
          when "@k", "@>", "@[", "@]", "@{", "@}", "@|", "@y", "@e", "@t", "@-"
            # Tags whose content should be processed for potential line breaks.

            # Some of these tags cause style changes that need to be tracked:
            @style = :bold if tag == "@{"
            @style = :regular if tag == "@}"

            append_raw(tag)
            append_chars(content)
          when "@b"
            # Tags whose content should neither have line breaks inserted nor
            # count for line length (furigana top text)
            append_raw(tag)
            append_raw(content)
          when "@<"
            # Tags whose content should not have line breaks inserted but
            # which *should* count for line length (furigana bottom text)
            append_raw(tag)
            append_chars(content, no_break: true)
          when "@v", "@w", "@o", "@a", "@z", "@c", "@s"
            # Tags that take some extra data delimited by a period, but other
            # than that the content should be processed normally (colour, voice,
            # etc.)
            parameter, text = content.split(".", 2)
            parameter ||= ""
            text ||= ""

            # If we are handling a font size tag we need to adjust the internal
            # scale:
            @scale = [2.0, parameter.to_i / 100.0].min if tag == "@z"

            append_raw(tag + parameter + ".")
            append_chars(text)
          when "@u"
            # Unicode character tag, the tag parameter is a decimal number
            # specifying the Unicode codepoint to insert. ('@u229.' => 'å')
            parameter, text = content.split(".", 2)
            parameter ||= ""
            text ||= ""

            char = [parameter.to_i].pack('U')

            # We need to append the tag with its parameter as "one character",
            # so that the game will correctly show the Unicode character we
            # need. However, the width of the underlying character must be
            # used instead of the "width of the tag"
            width = char_width(char)
            append_char(tag + parameter + ".", width_override: width)

            # Append the content following the tag as normal
            append_chars(text)
          when "@r"
            # Newline tag, needs to be processed separately as it should reset
            # the tracked line length
            newline
            append_chars(content)
          else
            raise "Unrecognised dialogue tag: #{tag}"
          end
        else
          # The initial text before any tag — if it exists — is always the
          # character name. This is not relevant for line breaking purposes,
          # so we can ignore it in this regard and just append it as raw text
          append_raw(e)
        end
      end

      # Make sure to include the text that is now saved in @current_element
      next_element

      # We are done processing the text! Now join the elements together, that
      # will be our result
      @elements.map(&:content).join
    end

    private

    # Append newline tag and reset tracked line length
    def newline
      append_raw("@r")
      @current_line_length = 0
    end

    # Adds the current element to the end of @elements, doing the relevant
    # processing and resetting the relevant variables.
    def next_element(should_break = false)
      @elements << Element.new(@current_element, should_break)
      @current_line_length += @current_element_length
      @current_element_length = 0
      @current_element = ""
    end

    # Check whether we have exceeded the textbox width and need to break at
    # this time
    def check_break
      if @current_line_length + @current_element_length > @width
        if @current_line_length == 0
          # We have hit the textbox width from just the length of the current
          # element. This means we are in a very long section that can not be
          # broken in the usual way in the middle, so we give up here, insert a
          # newline in the middle of the text and reset the current tracked
          # length.
          @current_element += "@r"
          @current_element_length = 0
          return # Don't do the normal processing here as it would be redundant
        end

        # Remove breakable elements from the end (so we don't have dangling
        # spaces or something like that)
        last_non_breaking_index = @elements.rindex { |e| !e.can_break? }
        @elements = @elements[0..last_non_breaking_index] unless last_non_breaking_index.nil?

        # Add a newline
        @elements << Element.new("@r", false)

        # Reset line length
        @current_line_length = 0
      end
    end

    # Append multiple characters at once
    def append_chars(chars, no_break: false)
      chars.each_char { |char| append_char(char, no_break: no_break) }
    end

    # Append one character
    def append_char(char, no_break: false, width_override: nil)
      width = width_override || char_width(char)

      if can_break_on?(char) && !no_break
        next_element
        @current_element_length += width
        append_raw(char)
        next_element(true)
      else
        @current_element_length += width
        append_raw(char)
      end

      check_break
    end

    # Append raw content (without tracking character widths)
    def append_raw(content)
      @current_element << content
    end

    # Check whether it is possible to break on a particular character (i.e. that
    # character is whitespace)
    def can_break_on?(character)
      character.match?(/\p{Space}/)
    end
  end
end
