# frozen_string_literal: true

module Chamomile
  module Layout
    class Panel < Base
      attr_reader :children

      def self.border_map
        @border_map ||= {
          rounded: Chamomile::Border::ROUNDED,
          normal:  Chamomile::Border::NORMAL,
          thick:   Chamomile::Border::THICK,
          double:  Chamomile::Border::DOUBLE,
          ascii:   Chamomile::Border::ASCII,
          none:    nil,
        }.freeze
      end

      def initialize(title: nil, width: nil, border: :rounded, color: nil, focused: false)
        @title    = title
        @width    = width
        @border   = border
        @color    = color || (focused ? "#7d56f4" : "#444444")
        @focused  = focused
        @children = []
      end

      def add(child)
        @children << child
        self
      end

      def explicit_width?
        !@width.nil?
      end

      def resolved_width(available_width)
        return available_width unless @width
        if @width.is_a?(String) && @width.end_with?("%")
          pct = @width.to_f / 100.0
          (available_width * pct).to_i
        else
          @width.to_i
        end
      end

      def render(width:, height:)
        my_width     = resolved_width(width)
        inner_width  = [my_width - 2, 0].max
        inner_height = [height - 2, 0].max

        inner_content = @children.map { |c| c.render(width: inner_width, height: inner_height) }.join("\n")

        style = Chamomile::Style.new
          .width(my_width)
          .height(height)
          .border_foreground(@color)

        border_preset = self.class.border_map[@border] || Chamomile::Border::ROUNDED
        style = style.border(border_preset) if border_preset

        if @title && border_preset
          rendered = style.render(inner_content)
          inject_title(rendered, @title, @color)
        else
          style.render(inner_content)
        end
      end

      private

      def inject_title(rendered, title, color)
        lines = rendered.split("\n", -1)
        return rendered if lines.empty?
        styled_title = Chamomile::Style.new.foreground(color).render(" #{title} ")
        lines[0] = lines[0].sub(/─{2,}/, "─#{styled_title}─")
        lines.join("\n")
      end
    end
  end
end
