# frozen_string_literal: true

module Chamomile
  module Layout
    class Text < Base
      def initialize(content, bold: false, italic: false, color: nil,
                     dim: false, width: nil, align: :left)
        @content = content.to_s
        @bold    = bold
        @italic  = italic
        @color   = color
        @dim     = dim
        @width   = width
        @align   = align
      end

      def render(width:, height:)
        style = Flourish::Style.new
        style = style.bold             if @bold
        style = style.italic           if @italic
        style = style.faint            if @dim
        style = style.foreground(@color) if @color
        style = style.width(@width || width)
        style = style.align_horizontal(@align)
        style.render(@content)
      end
    end
  end
end
