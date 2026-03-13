# frozen_string_literal: true

module Chamomile
  module Align
    class << self
      def horizontal(lines, width, position)
        lines.map do |line|
          line_width = ANSI.printable_width(line)
          gap = width - line_width
          next line if gap <= 0

          left_pad = (gap * position).round
          right_pad = gap - left_pad
          "#{" " * left_pad}#{line}#{" " * right_pad}"
        end
      end

      def vertical(lines, height, position)
        gap = height - lines.length
        return lines if gap <= 0

        top_pad = (gap * position).round
        bottom_pad = gap - top_pad

        result = []
        top_pad.times { result << "" }
        result.concat(lines)
        bottom_pad.times { result << "" }
        result
      end
    end
  end
end
