# frozen_string_literal: true

module Chamomile
  module Layout
    class Spinner < Base
      def initialize(label: nil, color: "#7d56f4")
        @label = label
        @color = color
        @spinner = Chamomile::Spinner.new
      end

      def render(width:, height:)
        view = @spinner.view
        view += " #{@label}" if @label
        Chamomile::Style.new.foreground(@color).render(view)
      end
    end
  end
end
