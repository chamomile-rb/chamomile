# frozen_string_literal: true

module Chamomile
  module Join
    class << self
      def horizontal(position, *strs)
        strs = strs.flatten
        return "" if strs.empty?

        blocks = strs.map { |s| s.split("\n", -1) }
        max_height = blocks.map(&:length).max

        # Equalize heights using position for vertical alignment
        blocks = blocks.map do |lines|
          if lines.length < max_height
            Align.vertical(lines, max_height, position)
          else
            lines
          end
        end

        # Find max width of each block
        widths = blocks.map do |lines|
          lines.map { |l| ANSI.printable_width(l) }.max || 0
        end

        # Join line by line
        (0...max_height).map do |row|
          blocks.each_with_index.map do |lines, idx|
            line = lines[row] || ""
            # Pad all blocks except the last to their max width
            if idx < blocks.length - 1
              line_width = ANSI.printable_width(line)
              pad = widths[idx] - line_width
              pad.positive? ? "#{line}#{" " * pad}" : line
            else
              line
            end
          end.join
        end.join("\n")
      end

      def vertical(position, *strs)
        strs = strs.flatten
        return "" if strs.empty?

        blocks = strs.map { |s| s.split("\n", -1) }

        # Find max width across all blocks
        max_width = blocks.flat_map { |lines| lines.map { |l| ANSI.printable_width(l) } }.max || 0

        # Align each block's lines horizontally
        all_lines = blocks.flat_map do |lines|
          Align.horizontal(lines, max_width, position)
        end

        all_lines.join("\n")
      end
    end
  end
end
