# frozen_string_literal: true

module Chamomile
  module Layout
    class StatusBar < Base
      def initialize(content, color: "#666666")
        @content = content.to_s
        @color   = color
      end

      def render(width:, height:)
        Chamomile::Style.new
          .foreground(@color)
          .width(width)
          .render(@content)
      end
    end
  end
end
