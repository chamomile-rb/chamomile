# frozen_string_literal: true

module Chamomile
  module Layout
    class Vertical < Base
      def initialize(align: :left)
        @align    = align
        @children = []
      end

      def add(child)
        @children << child
        self
      end

      def render(width:, height:)
        return "" if @children.empty?
        parts = @children.map { |c| c.render(width: width, height: height) }
        Flourish.vertical(parts, align: @align)
      end
    end
  end
end
