# frozen_string_literal: true

module Chamomile
  module Layout
    class Horizontal < Base
      def initialize(align: :top)
        @align    = align
        @children = []
      end

      def add(child)
        @children << child
        self
      end

      def render(width:, height:)
        return "" if @children.empty?

        explicit  = @children.select { |c| c.respond_to?(:explicit_width?) && c.explicit_width? }
        flexible  = @children - explicit

        used = explicit.sum { |c| c.resolved_width(width) }
        flex_width = flexible.empty? ? 0 : (width - used) / flexible.size

        parts = @children.map do |child|
          w = explicit.include?(child) ? child.resolved_width(width) : flex_width
          child.render(width: w, height: height)
        end

        Flourish.horizontal(parts, align: @align)
      end
    end
  end
end
