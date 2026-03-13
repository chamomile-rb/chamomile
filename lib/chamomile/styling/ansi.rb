# frozen_string_literal: true

module Chamomile
  module ANSI
    # Matches CSI sequences, OSC sequences, ESC charset/other sequences
    ESCAPE_RE = /\e\[[0-9;]*[A-Za-z]|\e\][^\a\e]*(?:\a|\e\\)|\e[()][AB012]|\e./

    class << self
      def strip(str)
        str.gsub(ESCAPE_RE, "")
      end

      def printable_width(str)
        stripped = strip(str)
        width = 0
        stripped.each_char do |ch|
          width += char_width(ch)
        end
        width
      end

      def height(str)
        str.count("\n") + 1
      end

      def size(str)
        return [0, 1] if str.empty?

        lines = str.split("\n", -1)
        w = lines.map { |line| printable_width(line) }.max || 0
        [w, lines.length]
      end

      def extract_escape(chars, start)
        return nil unless chars[start] == "\e"

        i = start + 1
        return nil if i >= chars.length

        if chars[i] == "["
          seq = +"\e["
          i += 1
          while i < chars.length && chars[i].match?(/[0-9;]/)
            seq << chars[i]
            i += 1
          end
          if i < chars.length && chars[i].match?(/[A-Za-z]/)
            seq << chars[i]
            return seq
          end
        end

        nil
      end

      def track_sgr(active_sgr, seq)
        if ["\e[0m", "\e[m"].include?(seq)
          active_sgr.clear
        elsif seq.match?(/\A\e\[\d/)
          if active_sgr.empty?
            active_sgr.replace(seq)
          else
            active_sgr.replace("#{active_sgr.delete_suffix("\e[0m")}#{seq}")
          end
        end
      end

      def sgr_open_after?(was_open, seq)
        return false if ["\e[0m", "\e[m"].include?(seq)
        return true if seq.match?(/\A\e\[\d/)

        was_open
      end

      private

      def char_width(ch)
        cp = ch.ord
        return 2 if cjk?(cp)
        return 0 if cp < 32 || (cp >= 0x7F && cp < 0xA0)

        1
      end

      def cjk?(cp)
        cp.between?(0x1100, 0x115F) || # Hangul Jamo
          cp == 0x2329 || cp == 0x232A || # Angle brackets
          cp.between?(0x2E80, 0x303E) ||  # CJK Radicals..CJK Symbols
          cp.between?(0x3040, 0x33BF) ||  # Hiragana..CJK Compatibility
          cp.between?(0x3400, 0x4DBF) ||  # CJK Unified Ext A
          cp.between?(0x4E00, 0xA4CF) ||  # CJK Unified..Yi Radicals
          cp.between?(0xAC00, 0xD7A3) ||  # Hangul Syllables
          cp.between?(0xF900, 0xFAFF) ||  # CJK Compatibility Ideographs
          cp.between?(0xFE10, 0xFE6F) ||  # Vertical forms..Small forms
          cp.between?(0xFF01, 0xFF60) ||  # Fullwidth forms
          cp.between?(0xFFE0, 0xFFE6) ||  # Fullwidth signs
          cp.between?(0x1F300, 0x1F9FF) || # Misc Symbols/Emoji
          cp.between?(0x20000, 0x2FFFD) || # CJK Ext B..
          cp.between?(0x30000, 0x3FFFD) # CJK Ext G..
      end
    end
  end
end
