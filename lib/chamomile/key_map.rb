# frozen_string_literal: true

module Chamomile
  # Backward-compat sequence-to-KeyMsg translator (delegates to EscapeParser).
  module KeyMap
    SEQUENCES = {
      "\e[A" => [:up,        []],
      "\e[B" => [:down,      []],
      "\e[C" => [:right,     []],
      "\e[D" => [:left,      []],
      "\e[H" => [:home,      []],
      "\e[F" => [:end_key,   []],
      "\e[5~" => [:page_up,   []],
      "\e[6~" => [:page_down, []],
      "\e[2~" => [:insert,    []],
      "\e[3~" => [:delete,    []],
      "\eOP" => [:f1,        []],
      "\eOQ" => [:f2,        []],
      "\eOR" => [:f3,        []],
      "\eOS" => [:f4,        []],
      "\e[15~" => [:f5,        []],
      "\e[17~" => [:f6,        []],
      "\e[18~" => [:f7,        []],
      "\e[19~" => [:f8,        []],
      "\e[20~" => [:f9,        []],
      "\e[21~" => [:f10,       []],
      "\e[23~" => [:f11,       []],
      "\e[24~" => [:f12,       []],

      # Ctrl key combos (C0 control codes)
      "\x01" => ["a", [:ctrl]],
      "\x02" => ["b", [:ctrl]],
      "\x03" => ["c", [:ctrl]],
      "\x04" => ["d", [:ctrl]],
      "\x05" => ["e", [:ctrl]],
      "\x06" => ["f", [:ctrl]],
      "\x07" => ["g", [:ctrl]],
      "\x08" => [:backspace, []],
      "\x09" => [:tab,       []],
      "\x0a" => [:enter,     []],
      "\x0b" => ["k", [:ctrl]],
      "\x0c" => ["l", [:ctrl]],
      "\x0d" => [:enter, []],
      "\x0e" => ["n", [:ctrl]],
      "\x0f" => ["o", [:ctrl]],
      "\x10" => ["p", [:ctrl]],
      "\x11" => ["q", [:ctrl]],
      "\x12" => ["r", [:ctrl]],
      "\x13" => ["s", [:ctrl]],
      "\x14" => ["t", [:ctrl]],
      "\x15" => ["u", [:ctrl]],
      "\x16" => ["v", [:ctrl]],
      "\x17" => ["w", [:ctrl]],
      "\x18" => ["x", [:ctrl]],
      "\x19" => ["y", [:ctrl]],
      "\x1a" => ["z", [:ctrl]],
      "\x1b" => [:escape, []],
      "\x7f" => [:backspace, []],
    }.freeze

    # Backward-compat wrapper: translates a complete byte sequence into a message.
    # New code should use EscapeParser directly for streaming/buffered parsing.
    def self.translate(bytes)
      # For bare ESC, use the static map (parser would need a timeout to flush it)
      return KeyMsg.new(key: :escape, mod: []) if bytes == "\x1b"

      # Use parser for everything else
      msgs = []
      parser = EscapeParser.new
      parser.feed(bytes) { |msg| msgs << msg }
      parser.timeout! { |msg| msgs << msg }

      msgs.first || KeyMsg.new(key: bytes, mod: [:unknown])
    end
  end
end
