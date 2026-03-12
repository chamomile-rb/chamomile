# frozen_string_literal: true

module Chamomile
  # Declarative view DSL. Build a widget tree from view, the renderer
  # calls frame.render(width:, height:) to produce the final string.
  #
  #   def view
  #     Chamomile::Frame.build do |f|
  #       f.horizontal do |left, right|
  #         left.panel("Routes") { left.text @routes }
  #         right.panel("Detail") { right.text @detail }
  #       end
  #       f.status_bar @status
  #     end
  #   end
  class Frame
    attr_reader :children

    def self.build(&block)
      frame = new
      block.call(frame) if block
      frame
    end

    def initialize
      @children = []
    end

    # Add a vertical layout container.
    def vertical(&block)
      layout = Widgets::VerticalLayout.new
      block.call(layout) if block
      @children << layout
      layout
    end

    # Add a horizontal layout container.
    def horizontal(&block)
      layout = Widgets::HorizontalLayout.new
      block.call(layout) if block
      @children << layout
      layout
    end

    # Add a bordered panel with a title.
    def panel(title = nil, border: :rounded, width: nil, &block)
      p = Widgets::Panel.new(title: title, border: border, width: width)
      block.call(p) if block
      @children << p
      p
    end

    # Add a plain text block.
    def text(content)
      t = Widgets::Text.new(content: content.to_s)
      @children << t
      t
    end

    # Add a status bar (fixed bottom line).
    def status_bar(content)
      sb = Widgets::StatusBar.new(content: content.to_s)
      @children << sb
      sb
    end

    # Render the frame to a string.
    def render(width:, height:)
      return "" if @children.empty?

      if @children.length == 1
        @children[0].render(width: width, height: height)
      else
        # Default: stack children vertically
        lines = []
        remaining_height = height
        @children.each_with_index do |child, i|
          child_height = if i == @children.length - 1
                           remaining_height
                         else
                           [remaining_height / (@children.length - i), 1].max
                         end
          lines << child.render(width: width, height: child_height)
          remaining_height -= child_height
        end
        lines.join("\n")
      end
    end

    def to_s
      render(width: 80, height: 24)
    end
  end

  module Widgets
    # Plain text block.
    class Text
      attr_reader :content

      def initialize(content: "")
        @content = content
      end

      def render(width: 80, height: 24)
        lines = @content.split("\n", -1)
        lines = lines[0, height] if lines.length > height
        lines.map { |l| l.length > width ? l[0, width] : l }.join("\n")
      end
    end

    # Bordered panel with optional title.
    class Panel
      attr_reader :title, :children

      def initialize(title: nil, border: :rounded, width: nil)
        @title = title
        @border = border
        @width = width
        @children = []
      end

      def text(content)
        t = Text.new(content: content.to_s)
        @children << t
        t
      end

      def render(width: 80, height: 24)
        w = @width || width
        inner_w = [w - 2, 0].max
        inner_h = [height - 2, 0].max

        # Render children
        content_lines = []
        @children.each do |child|
          content_lines.concat(child.render(width: inner_w, height: inner_h).split("\n", -1))
        end

        # Pad or truncate to inner height
        content_lines = content_lines[0, inner_h] if content_lines.length > inner_h
        while content_lines.length < inner_h
          content_lines << ""
        end

        border_chars = resolve_border
        top_line = build_top(border_chars, inner_w)
        bottom_line = "#{border_chars[:bl]}#{"#{border_chars[:h]}" * inner_w}#{border_chars[:br]}"

        body = content_lines.map do |line|
          padded = line.length < inner_w ? "#{line}#{" " * (inner_w - line.length)}" : line[0, inner_w]
          "#{border_chars[:v]}#{padded}#{border_chars[:v]}"
        end

        [top_line, *body, bottom_line].join("\n")
      end

      private

      def build_top(bc, inner_w)
        if @title && !@title.empty?
          title_text = " #{@title} "
          bar_remaining = [inner_w - title_text.length, 0].max
          "#{bc[:tl]}#{title_text}#{"#{bc[:h]}" * bar_remaining}#{bc[:tr]}"
        else
          "#{bc[:tl]}#{"#{bc[:h]}" * inner_w}#{bc[:tr]}"
        end
      end

      def resolve_border
        case @border
        when :rounded
          { tl: "\u256d", tr: "\u256e", bl: "\u2570", br: "\u256f", h: "\u2500", v: "\u2502" }
        when :normal
          { tl: "\u250c", tr: "\u2510", bl: "\u2514", br: "\u2518", h: "\u2500", v: "\u2502" }
        when :thick
          { tl: "\u250f", tr: "\u2513", bl: "\u2517", br: "\u251b", h: "\u2501", v: "\u2503" }
        when :double
          { tl: "\u2554", tr: "\u2557", bl: "\u255a", br: "\u255d", h: "\u2550", v: "\u2551" }
        else
          { tl: "\u256d", tr: "\u256e", bl: "\u2570", br: "\u256f", h: "\u2500", v: "\u2502" }
        end
      end
    end

    # Horizontal layout — splits width among children.
    class HorizontalLayout
      attr_reader :children

      def initialize
        @children = []
      end

      def panel(title = nil, border: :rounded, width: nil, &block)
        p = Panel.new(title: title, border: border, width: width)
        block.call(p) if block
        @children << p
        p
      end

      def text(content)
        t = Text.new(content: content.to_s)
        @children << t
        t
      end

      def render(width: 80, height: 24)
        return "" if @children.empty?

        child_width = width / @children.length
        parts = @children.map { |c| c.render(width: child_width, height: height) }

        # Join horizontally line-by-line
        all_lines = parts.map { |p| p.split("\n", -1) }
        max_lines = all_lines.map(&:length).max || 0
        all_lines.each { |ls| ls << "" while ls.length < max_lines }

        (0...max_lines).map do |row|
          all_lines.map { |ls| ls[row] || "" }.join
        end.join("\n")
      end
    end

    # Vertical layout — stacks children.
    class VerticalLayout
      attr_reader :children

      def initialize
        @children = []
      end

      def panel(title = nil, border: :rounded, width: nil, &block)
        p = Panel.new(title: title, border: border, width: width)
        block.call(p) if block
        @children << p
        p
      end

      def text(content)
        t = Text.new(content: content.to_s)
        @children << t
        t
      end

      def horizontal(&block)
        layout = HorizontalLayout.new
        block.call(layout) if block
        @children << layout
        layout
      end

      def status_bar(content)
        sb = StatusBar.new(content: content.to_s)
        @children << sb
        sb
      end

      def render(width: 80, height: 24)
        return "" if @children.empty?

        lines = []
        remaining = height
        @children.each_with_index do |child, i|
          child_height = if i == @children.length - 1
                           remaining
                         else
                           [remaining / (@children.length - i), 1].max
                         end
          lines << child.render(width: width, height: child_height)
          remaining -= child_height
        end
        lines.join("\n")
      end
    end

    # Fixed bottom status bar.
    class StatusBar
      def initialize(content: "")
        @content = content
      end

      def render(width: 80, height: 1)
        line = @content.length > width ? @content[0, width] : @content
        line
      end
    end
  end
end
