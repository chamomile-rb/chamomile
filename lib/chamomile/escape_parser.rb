# frozen_string_literal: true

module Chamomile
  # State-machine parser for ANSI escape sequences, CSI params, SGR mouse, and bracketed paste.
  class EscapeParser
    # States
    GROUND   = :ground
    ESC_SEEN = :esc_seen
    CSI_ENTRY = :csi_entry
    SS3      = :ss3
    PASTE    = :paste

    # CSI modifier mapping (xterm-style: param 2=Shift, 3=Alt, 4=Shift+Alt, 5=Ctrl, etc.)
    MODIFIER_MAP = {
      2 => [:shift],
      3 => [:alt],
      4 => %i[shift alt],
      5 => [:ctrl],
      6 => %i[ctrl shift],
      7 => %i[ctrl alt],
      8 => %i[ctrl shift alt],
    }.freeze

    PASTE_START = "\e[200~"
    PASTE_END   = "\e[201~"

    # Maximum paste buffer size (1MB) to prevent memory exhaustion
    MAX_PASTE_SIZE = 1_048_576

    def initialize
      @state = GROUND
      @buf = +""
      @paste_buf = +""
    end

    # Feed raw bytes into the parser, yielding parsed messages.
    def feed(bytes, &block)
      bytes.each_char { |ch| process_char(ch, &block) }
    end

    # Call when IO.select times out — flushes ambiguous ESC as :escape key.
    def timeout!
      return unless @state == ESC_SEEN

      @state = GROUND
      @buf.clear
      yield KeyMsg.new(key: :escape, mod: [])
    end

    private

    def process_char(ch, &)
      case @state
      when GROUND
        ground_char(ch, &)
      when ESC_SEEN
        esc_seen_char(ch, &)
      when CSI_ENTRY
        csi_char(ch, &)
      when SS3
        ss3_char(ch, &)
      when PASTE
        paste_char(ch, &)
      end
    end

    def ground_char(ch)
      case ch
      when "\x00"
        # NUL byte — ignore
      when "\e"
        @state = ESC_SEEN
        @buf = +"\e"
      when "\r", "\n"
        yield KeyMsg.new(key: :enter, mod: [])
      when "\t"
        yield KeyMsg.new(key: :tab, mod: [])
      when "\x7f", "\x08"
        yield KeyMsg.new(key: :backspace, mod: [])
      when ->(c) { c.ord.between?(1, 26) }
        letter = (ch.ord + 96).chr # \x01 -> 'a', \x02 -> 'b', etc.
        yield KeyMsg.new(key: letter, mod: [:ctrl])
      when ->(c) { c.ord >= 32 }
        yield KeyMsg.new(key: ch, mod: [])
      end
    end

    def esc_seen_char(ch)
      case ch
      when "["
        @state = CSI_ENTRY
        @buf << ch
      when "O"
        @state = SS3
        @buf << ch
      when "\e"
        # Another ESC: flush previous ESC as :escape, start new ESC
        yield KeyMsg.new(key: :escape, mod: [])
        @buf = +"\e"
        # Stay in ESC_SEEN
      else
        # Alt + char: ESC followed by a printable character
        @state = GROUND
        @buf.clear
        if ["\x7f", "\x08"].include?(ch)
          yield KeyMsg.new(key: :backspace, mod: [:alt])
        elsif ch.ord >= 32
          yield KeyMsg.new(key: ch, mod: [:alt])
        elsif ["\r", "\n"].include?(ch)
          yield KeyMsg.new(key: :enter, mod: [:alt])
        elsif ch == "\t"
          yield KeyMsg.new(key: :tab, mod: [:alt])
        elsif ch.ord.between?(1, 26)
          letter = (ch.ord + 96).chr
          yield KeyMsg.new(key: letter, mod: %i[alt ctrl])
        end
      end
    end

    def csi_char(ch, &)
      @buf << ch

      case ch
      when "0".."9", ";", ":"
        # Still collecting parameters; stay in CSI_ENTRY
        return
      when "<"
        # SGR mouse prefix — stay collecting
        return if @buf == "\e[<"

        # Already past the <, this is a parameter char
        return
      end

      # We have a final character — dispatch
      @state = GROUND
      seq = @buf.dup
      @buf.clear

      dispatch_csi(seq, &)
    end

    def ss3_char(ch)
      @buf << ch
      @state = GROUND
      seq = @buf.dup
      @buf.clear

      case ch
      when "P" then yield KeyMsg.new(key: :f1, mod: [])
      when "Q" then yield KeyMsg.new(key: :f2, mod: [])
      when "R" then yield KeyMsg.new(key: :f3, mod: [])
      when "S" then yield KeyMsg.new(key: :f4, mod: [])
      when "A" then yield KeyMsg.new(key: :up, mod: [])
      when "B" then yield KeyMsg.new(key: :down, mod: [])
      when "C" then yield KeyMsg.new(key: :right, mod: [])
      when "D" then yield KeyMsg.new(key: :left, mod: [])
      when "H" then yield KeyMsg.new(key: :home, mod: [])
      when "F" then yield KeyMsg.new(key: :end_key, mod: [])
      else
        yield KeyMsg.new(key: seq, mod: [:unknown])
      end
    end

    def dispatch_csi(seq, &)
      # Check for bracketed paste start/end
      if seq == PASTE_START
        @state = PASTE
        @paste_buf.clear
        return
      end

      if seq == PASTE_END
        # Shouldn't happen in CSI (we'd be in PASTE state), but handle gracefully
        yield PasteMsg.new(content: @paste_buf.dup)
        @paste_buf.clear
        return
      end

      # Focus/Blur: \e[I (focus) and \e[O (blur)
      if seq == "\e[I"
        yield FocusMsg.new
        return
      end
      if seq == "\e[O"
        yield BlurMsg.new
        return
      end

      # SGR mouse: \e[<Cb;Cx;CyM or \e[<Cb;Cx;Cym
      if seq.start_with?("\e[<") && (seq.end_with?("M") || seq.end_with?("m"))
        dispatch_sgr_mouse(seq, &)
        return
      end

      # Parse CSI parameters: \e[ params final
      body = seq[2..] # strip "\e["
      final = body[-1]
      params_str = body[0..-2]

      # Split params by ";"
      params = params_str.split(";").map { |p| p.empty? ? 1 : p.to_i }

      case final
      when "A" then yield key_with_modifiers(:up, params)
      when "B" then yield key_with_modifiers(:down, params)
      when "C" then yield key_with_modifiers(:right, params)
      when "D" then yield key_with_modifiers(:left, params)
      when "H" then yield key_with_modifiers(:home, params)
      when "F" then yield key_with_modifiers(:end_key, params)
      when "Z" then yield KeyMsg.new(key: :tab, mod: [:shift]) # Shift+Tab
      when "~"
        dispatch_tilde(params, &)
      else
        yield KeyMsg.new(key: seq, mod: [:unknown])
      end
    end

    def dispatch_tilde(params)
      key_code = params[0]
      mod = extract_modifiers(params[1]) if params.length > 1

      key = case key_code
            when 1  then :home
            when 2  then :insert
            when 3  then :delete
            when 4  then :end_key
            when 5  then :page_up
            when 6  then :page_down
            when 15 then :f5
            when 17 then :f6
            when 18 then :f7
            when 19 then :f8
            when 20 then :f9
            when 21 then :f10
            when 23 then :f11
            when 24 then :f12
            when 200
              @state = PASTE
              @paste_buf.clear
              return
            when 201
              yield PasteMsg.new(content: @paste_buf.dup)
              @paste_buf.clear
              return
            else
              return yield KeyMsg.new(key: "\e[#{params.join(";")}~", mod: [:unknown])
            end

      yield KeyMsg.new(key: key, mod: mod || [])
    end

    def dispatch_sgr_mouse(seq)
      # Format: \e[<Cb;Cx;CyM (press) or \e[<Cb;Cx;Cym (release)
      pressed = seq.end_with?("M")
      body = seq[3..-2] # strip "\e[<" and final char
      parts = body.split(";")
      return if parts.length < 3

      cb = parts[0].to_i
      cx = parts[1].to_i
      cy = parts[2].to_i

      # Extract modifiers from button code
      mod = []
      mod << :shift if cb.anybits?(4)
      mod << :alt   if cb.anybits?(8)
      mod << :ctrl  if cb.anybits?(16)

      # Extract button and action
      base = cb & 3
      motion = cb.anybits?(32)
      wheel = cb.anybits?(64)

      if wheel
        button = base.zero? ? MOUSE_WHEEL_UP : MOUSE_WHEEL_DOWN
        action = MOUSE_PRESS
      elsif motion
        button = resolve_button(base)
        action = MOUSE_MOTION
      else
        button = resolve_button(base)
        action = pressed ? MOUSE_PRESS : MOUSE_RELEASE
      end

      yield MouseMsg.new(x: cx, y: cy, button: button, action: action, mod: mod)
    end

    def paste_char(ch)
      @paste_buf << ch

      # Check if paste buffer ends with the paste-end sequence
      if @paste_buf.end_with?(PASTE_END)
        content = @paste_buf[0..-(PASTE_END.length + 1)]
        @paste_buf.clear
        @state = GROUND
        yield PasteMsg.new(content: content)
      elsif @paste_buf.bytesize > MAX_PASTE_SIZE
        # Prevent memory exhaustion — flush what we have and reset
        content = @paste_buf.dup
        @paste_buf.clear
        @state = GROUND
        yield PasteMsg.new(content: content)
      end
    end

    def resolve_button(base)
      case base
      when 0 then MOUSE_LEFT
      when 1 then MOUSE_MIDDLE
      when 2 then MOUSE_RIGHT
      else MOUSE_NONE
      end
    end

    def key_with_modifiers(key, params)
      if params.length >= 2
        mod = extract_modifiers(params[1])
        KeyMsg.new(key: key, mod: mod)
      else
        KeyMsg.new(key: key, mod: [])
      end
    end

    def extract_modifiers(code)
      MODIFIER_MAP[code] || []
    end
  end
end
