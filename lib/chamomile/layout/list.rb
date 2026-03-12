# frozen_string_literal: true

module Chamomile
  module Layout
    class List < Base
      def initialize(items, cursor: 0, height: nil,
                     selected_color: "#7d56f4", dim_color: "#888888")
        @items          = Array(items)
        @cursor         = cursor
        @height         = height
        @selected_color = selected_color
        @dim_color      = dim_color
      end

      def render(width:, height:)
        display_height = @height || height
        visible_items  = @items.first(display_height)

        lines = visible_items.each_with_index.map do |item, i|
          text = item.to_s.ljust(width)
          if i == @cursor
            Flourish::Style.new.foreground(@selected_color).reverse.render(text)
          else
            Flourish::Style.new.foreground(@dim_color).render(text)
          end
        end

        lines.join("\n")
      end
    end
  end
end
