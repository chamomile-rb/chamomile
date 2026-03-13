# frozen_string_literal: true

module Chamomile
  module Place
    class << self
      def place(width, height, h_pos, v_pos, str)
        lines = str.split("\n", -1)

        # Horizontal placement
        lines = Align.horizontal(lines, width, h_pos)

        # Vertical placement
        lines = Align.vertical(lines, height, v_pos)

        # Ensure all lines are padded to full width
        lines.map do |line|
          line_width = ANSI.printable_width(line)
          pad = width - line_width
          pad.positive? ? "#{line}#{" " * pad}" : line
        end.join("\n")
      end

      def place_horizontal(width, pos, str)
        lines = str.split("\n", -1)
        Align.horizontal(lines, width, pos).join("\n")
      end

      def place_vertical(height, pos, str)
        lines = str.split("\n", -1)
        Align.vertical(lines, height, pos).join("\n")
      end
    end
  end
end
