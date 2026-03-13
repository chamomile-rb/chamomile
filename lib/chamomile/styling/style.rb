# frozen_string_literal: true

module Chamomile
  class Style
    # Property symbols
    BOLD = :bold
    ITALIC = :italic
    FAINT = :faint
    BLINK = :blink
    STRIKETHROUGH = :strikethrough
    UNDERLINE = :underline
    REVERSE = :reverse
    FOREGROUND = :foreground
    BACKGROUND = :background
    TAB_WIDTH = :tab_width
    INLINE = :inline
    TRANSFORM = :transform
    WIDTH = :width
    HEIGHT = :height
    MAX_WIDTH = :max_width
    MAX_HEIGHT = :max_height
    PADDING_TOP = :padding_top
    PADDING_RIGHT = :padding_right
    PADDING_BOTTOM = :padding_bottom
    PADDING_LEFT = :padding_left
    MARGIN_TOP = :margin_top
    MARGIN_RIGHT = :margin_right
    MARGIN_BOTTOM = :margin_bottom
    MARGIN_LEFT = :margin_left
    BORDER_STYLE = :border_style
    BORDER_TOP = :border_top
    BORDER_RIGHT = :border_right
    BORDER_BOTTOM = :border_bottom
    BORDER_LEFT = :border_left
    BORDER_TOP_FG = :border_top_fg
    BORDER_RIGHT_FG = :border_right_fg
    BORDER_BOTTOM_FG = :border_bottom_fg
    BORDER_LEFT_FG = :border_left_fg
    BORDER_TOP_BG = :border_top_bg
    BORDER_RIGHT_BG = :border_right_bg
    BORDER_BOTTOM_BG = :border_bottom_bg
    BORDER_LEFT_BG = :border_left_bg
    ALIGN_HORIZONTAL = :align_horizontal
    ALIGN_VERTICAL = :align_vertical
    UNDERLINE_SPACES = :underline_spaces
    STRIKETHROUGH_SPACES = :strikethrough_spaces
    COLOR_WHITESPACE = :color_whitespace

    SGR_CODES = {
      BOLD => "1",
      FAINT => "2",
      ITALIC => "3",
      UNDERLINE => "4",
      BLINK => "5",
      REVERSE => "7",
      STRIKETHROUGH => "9",
    }.freeze

    DEFAULT_TAB_WIDTH = 4

    def initialize
      @set_props = Set.new
    end

    # --- Text attributes ---

    def bold(v = true) = assign_prop(:bold, v)
    def italic(v = true) = assign_prop(:italic, v)
    def faint(v = true) = assign_prop(:faint, v)
    def blink(v = true) = assign_prop(:blink, v)
    def strikethrough(v = true) = assign_prop(:strikethrough, v)
    def underline(v = true) = assign_prop(:underline, v)
    def reverse(v = true) = assign_prop(:reverse, v)

    # --- Colors ---

    def foreground(color) = assign_prop(:foreground, Color.parse(color))
    def background(color) = assign_prop(:background, Color.parse(color))

    # --- Utility ---

    def tab_width(n) = assign_prop(:tab_width, n)
    def inline(v = true) = assign_prop(:inline, v)

    def transform(&block)
      assign_prop(:transform, block)
    end

    # --- Dimensions ---

    def width(n) = assign_prop(:width, n)
    def height(n) = assign_prop(:height, n)
    def max_width(n) = assign_prop(:max_width, n)
    def max_height(n) = assign_prop(:max_height, n)

    # --- Padding (CSS shorthand) ---

    def padding(*args)
      top, right, bottom, left = expand_shorthand(args)
      copy = dup
      copy.set_prop!(:padding_top, top)
      copy.set_prop!(:padding_right, right)
      copy.set_prop!(:padding_bottom, bottom)
      copy.set_prop!(:padding_left, left)
      copy
    end

    def padding_top(n) = assign_prop(:padding_top, n)
    def padding_right(n) = assign_prop(:padding_right, n)
    def padding_bottom(n) = assign_prop(:padding_bottom, n)
    def padding_left(n) = assign_prop(:padding_left, n)

    # --- Margin (CSS shorthand) ---

    def margin(*args)
      top, right, bottom, left = expand_shorthand(args)
      copy = dup
      copy.set_prop!(:margin_top, top)
      copy.set_prop!(:margin_right, right)
      copy.set_prop!(:margin_bottom, bottom)
      copy.set_prop!(:margin_left, left)
      copy
    end

    def margin_top(n) = assign_prop(:margin_top, n)
    def margin_right(n) = assign_prop(:margin_right, n)
    def margin_bottom(n) = assign_prop(:margin_bottom, n)
    def margin_left(n) = assign_prop(:margin_left, n)

    # --- Border ---

    def border(style, *sides)
      copy = dup
      copy.set_prop!(:border_style, style)
      copy.send(:apply_border_sides, sides)
      copy
    end

    def border_style(style)
      assign_prop(:border_style, style)
    end

    def border_top(v = true) = assign_prop(:border_top, v)
    def border_right(v = true) = assign_prop(:border_right, v)
    def border_bottom(v = true) = assign_prop(:border_bottom, v)
    def border_left(v = true) = assign_prop(:border_left, v)

    def border_foreground(*colors)
      copy = dup
      copy.send(:apply_border_colors, colors, :fg)
      copy
    end

    def border_background(*colors)
      copy = dup
      copy.send(:apply_border_colors, colors, :bg)
      copy
    end

    def border_top_foreground(color) = assign_prop(:border_top_fg, Color.parse(color))
    def border_right_foreground(color) = assign_prop(:border_right_fg, Color.parse(color))
    def border_bottom_foreground(color) = assign_prop(:border_bottom_fg, Color.parse(color))
    def border_left_foreground(color) = assign_prop(:border_left_fg, Color.parse(color))
    def border_top_background(color) = assign_prop(:border_top_bg, Color.parse(color))
    def border_right_background(color) = assign_prop(:border_right_bg, Color.parse(color))
    def border_bottom_background(color) = assign_prop(:border_bottom_bg, Color.parse(color))
    def border_left_background(color) = assign_prop(:border_left_bg, Color.parse(color))

    # --- Alignment ---

    def align(*positions)
      copy = dup
      copy.set_prop!(:align_horizontal, Chamomile.resolve_position(positions[0])) if positions.length >= 1
      copy.set_prop!(:align_vertical, Chamomile.resolve_position(positions[1])) if positions.length >= 2
      copy
    end

    def align_horizontal(pos) = assign_prop(:align_horizontal, Chamomile.resolve_position(pos))
    def align_vertical(pos) = assign_prop(:align_vertical, Chamomile.resolve_position(pos))

    # --- Whitespace options ---

    def underline_spaces(v = true) = assign_prop(:underline_spaces, v)
    def strikethrough_spaces(v = true) = assign_prop(:strikethrough_spaces, v)
    def color_whitespace(v = true) = assign_prop(:color_whitespace, v)

    # --- Public query methods ---

    def bold? = !!@bold
    def italic? = !!@italic
    def faint? = !!@faint
    def blink? = !!@blink
    def strikethrough? = !!@strikethrough
    def underline? = !!@underline
    def reverse? = !!@reverse
    def inline? = !!@inline
    def foreground_color = @foreground
    def background_color = @background
    def border_top? = !!@border_top
    def border_right? = !!@border_right
    def border_bottom? = !!@border_bottom
    def border_left? = !!@border_left
    def underline_spaces? = !!@underline_spaces
    def strikethrough_spaces? = !!@strikethrough_spaces
    def color_whitespace? = !!@color_whitespace

    # --- Inheritance ---

    def inherit(other)
      copy = dup
      other.set_props.each do |prop|
        next if copy.set_props.include?(prop)

        copy.instance_variable_set(:"@#{prop}", other.instance_variable_get(:"@#{prop}"))
        copy.set_props.add(prop)
      end
      copy
    end

    def unset(*props)
      copy = dup
      props.each do |prop|
        copy.set_props.delete(prop)
        copy.instance_variable_set(:"@#{prop}", nil)
      end
      copy
    end

    def set?(prop)
      @set_props.include?(prop)
    end

    def copy
      dup
    end

    # Merge another style on top of this one. The other style's set properties win.
    def merge(other)
      return dup if other.nil?

      copy = dup
      other.set_props.each do |prop|
        copy.set_prop!(prop, other.instance_variable_get(:"@#{prop}"))
      end
      copy
    end

    # Empty style singleton
    EMPTY = new.freeze

    # --- Render ---

    def render(*strs)
      text = strs.join(" ")

      # Apply transform
      text = @transform.call(text) if @transform

      # Convert tabs
      tw = effective_tab_width
      text = text.gsub("\t", " " * tw) if tw.positive?

      # Calculate dimensions
      content_width = compute_content_width
      target_height = effective_height

      # Word wrap if width is set
      text = Wrap.word_wrap(text, content_width) if content_width.positive?

      lines = text.split("\n", -1)
      lines = [""] if lines.empty?

      # Apply text SGR per line
      sgr = build_sgr
      lines = apply_sgr_to_lines(lines, sgr)

      # Alignment (inside border, after SGR)
      lines = apply_alignment(lines, content_width) if content_width.positive?

      # Enforce inner content height (before padding/border)
      if target_height.positive?
        inner_height = compute_inner_height(target_height)
        lines = enforce_height(lines, inner_height) if inner_height.positive?
      end

      # Padding
      lines = apply_padding(lines)

      # Border
      lines = apply_border(lines) if effective_border_style

      # Margin
      lines = apply_margin(lines)

      # Enforce max constraints
      lines = enforce_max_width(lines)
      lines = enforce_max_height(lines)

      lines.join("\n")
    end

    protected

    # Accessible from other Style instances for inheritance
    attr_reader :set_props

    # Mutate a prop in place — used by multi-prop methods after dup
    def set_prop!(prop, value)
      instance_variable_set(:"@#{prop}", value)
      @set_props.add(prop)
    end

    def initialize_dup(other)
      super
      @set_props = @set_props.dup
    end

    private

    # --- Property assignment (immutable: returns a new Style) ---

    def assign_prop(prop, value)
      copy = dup
      copy.instance_variable_set(:"@#{prop}", value)
      copy.set_props.add(prop)
      copy
    end

    # --- CSS shorthand expansion ---

    def expand_shorthand(args)
      case args.size
      when 1 then [args[0]] * 4
      when 2 then [args[0], args[1], args[0], args[1]]
      when 3 then [args[0], args[1], args[2], args[1]]
      when 4 then args
      end
    end

    # --- Whitespace helper ---

    def spaces(n)
      n <= 0 ? "" : " " * n
    end

    # --- Internal getters ---

    def effective_tab_width = @tab_width || DEFAULT_TAB_WIDTH
    def effective_width = @width || 0
    def effective_height = @height || 0
    def effective_max_width = @max_width || 0
    def effective_max_height = @max_height || 0
    def effective_padding_top = @padding_top || 0
    def effective_padding_right = @padding_right || 0
    def effective_padding_bottom = @padding_bottom || 0
    def effective_padding_left = @padding_left || 0
    def effective_margin_top = @margin_top || 0
    def effective_margin_right = @margin_right || 0
    def effective_margin_bottom = @margin_bottom || 0
    def effective_margin_left = @margin_left || 0
    def effective_border_style = @border_style
    def effective_align_horizontal = @align_horizontal || 0.0
    def effective_align_vertical = @align_vertical || 0.0

    def compute_content_width
      w = effective_width
      return 0 if w <= 0

      w -= effective_padding_left + effective_padding_right
      w -= 1 if border_left?
      w -= 1 if border_right?
      [w, 0].max
    end

    def compute_inner_height(total_height)
      h = total_height
      h -= effective_padding_top + effective_padding_bottom
      h -= 1 if border_top?
      h -= 1 if border_bottom?
      [h, 0].max
    end

    def build_sgr
      parts = []

      parts << "1" if @bold
      parts << "2" if @faint
      parts << "3" if @italic
      parts << "4" if @underline
      parts << "5" if @blink
      parts << "7" if @reverse
      parts << "9" if @strikethrough

      parts << @foreground.fg_sequence if @foreground && !@foreground.no_color?
      parts << @background.bg_sequence if @background && !@background.no_color?

      parts.join(";")
    end

    def apply_sgr_to_lines(lines, sgr)
      return lines if sgr.empty?

      lines.map do |line|
        "\e[#{sgr}m#{line}\e[0m"
      end
    end

    def apply_alignment(lines, content_width)
      h_pos = effective_align_horizontal
      Align.horizontal(lines, content_width, h_pos)
    end

    def apply_padding(lines)
      pt = effective_padding_top
      pr = effective_padding_right
      pb = effective_padding_bottom
      pl = effective_padding_left

      return lines if pt.zero? && pr.zero? && pb.zero? && pl.zero?

      left_fill = spaces(pl)
      right_fill = spaces(pr)

      ws_sgr = build_whitespace_sgr
      unless ws_sgr.empty?
        left_fill = "\e[#{ws_sgr}m#{left_fill}\e[0m" unless left_fill.empty?
        right_fill = "\e[#{ws_sgr}m#{right_fill}\e[0m" unless right_fill.empty?
      end

      result = []
      blank_line = build_blank_padding_line(left_fill, right_fill, lines)
      pt.times { result << blank_line }
      lines.each { |line| result << "#{left_fill}#{line}#{right_fill}" }
      pb.times { result << blank_line }
      result
    end

    def build_blank_padding_line(left_fill, right_fill, lines)
      # Calculate the inner content width from existing lines
      inner_width = lines.map { |l| ANSI.printable_width(l) }.max || 0
      inner_fill = spaces(inner_width)
      ws_sgr = build_whitespace_sgr
      inner_fill = "\e[#{ws_sgr}m#{inner_fill}\e[0m" if !ws_sgr.empty? && !inner_fill.empty?
      "#{left_fill}#{inner_fill}#{right_fill}"
    end

    def build_whitespace_sgr
      return "" unless color_whitespace?

      parts = []
      parts << @background.bg_sequence if @background && !@background.no_color?
      parts.join(";")
    end

    def apply_border(lines)
      bs = effective_border_style
      return lines unless bs

      has_top = border_top?
      has_bottom = border_bottom?
      has_left = border_left?
      has_right = border_right?

      return lines unless has_top || has_bottom || has_left || has_right

      content_width = lines.map { |l| ANSI.printable_width(l) }.max || 0

      result = []

      if has_top
        top_line = build_border_top(bs, content_width, has_left, has_right)
        result << top_line
      end

      lines.each do |line|
        bordered = +""
        bordered << style_border_char(bs.left, :left) if has_left
        line_width = ANSI.printable_width(line)
        pad = content_width - line_width
        bordered << line
        bordered << (" " * pad) if pad.positive?
        bordered << style_border_char(bs.right, :right) if has_right
        result << bordered
      end

      if has_bottom
        bottom_line = build_border_bottom(bs, content_width, has_left, has_right)
        result << bottom_line
      end

      result
    end

    def build_border_top(bs, width, has_left, has_right)
      line = +""
      line << style_border_char(bs.top_left, :top) if has_left
      line << style_border_char(bs.top * width, :top)
      line << style_border_char(bs.top_right, :top) if has_right
      line
    end

    def build_border_bottom(bs, width, has_left, has_right)
      line = +""
      line << style_border_char(bs.bottom_left, :bottom) if has_left
      line << style_border_char(bs.bottom * width, :bottom)
      line << style_border_char(bs.bottom_right, :bottom) if has_right
      line
    end

    def style_border_char(char, side)
      fg = instance_variable_get(:"@border_#{side}_fg")
      bg = instance_variable_get(:"@border_#{side}_bg")

      parts = []
      parts << fg.fg_sequence if fg && !fg.no_color?
      parts << bg.bg_sequence if bg && !bg.no_color?

      return char if parts.empty?

      "\e[#{parts.join(";")}m#{char}\e[0m"
    end

    def enforce_height(lines, target_height)
      if lines.length < target_height
        v_pos = effective_align_vertical
        Align.vertical(lines, target_height, v_pos)
      elsif lines.length > target_height
        lines[0, target_height]
      else
        lines
      end
    end

    def apply_margin(lines)
      mt = effective_margin_top
      mr = effective_margin_right
      mb = effective_margin_bottom
      ml = effective_margin_left

      return lines if mt.zero? && mr.zero? && mb.zero? && ml.zero?

      left_fill = spaces(ml)
      right_fill = spaces(mr)

      result = []
      mt.times { result << "" }
      lines.each { |line| result << "#{left_fill}#{line}#{right_fill}" }
      mb.times { result << "" }
      result
    end

    def enforce_max_width(lines)
      mw = effective_max_width
      return lines if mw <= 0

      lines.map do |line|
        truncate_line(line, mw)
      end
    end

    def enforce_max_height(lines)
      mh = effective_max_height
      return lines if mh <= 0
      return lines if lines.length <= mh

      lines[0, mh]
    end

    def truncate_line(line, max_width)
      width = 0
      result = +""
      i = 0
      chars = line.chars
      has_open_sgr = false

      while i < chars.length
        seq = chars[i] == "\e" ? ANSI.extract_escape(chars, i) : nil
        if seq
          result << seq
          has_open_sgr = ANSI.sgr_open_after?(has_open_sgr, seq)
          i += seq.length
          next
        end

        ch_w = ANSI.printable_width(chars[i])
        break if width + ch_w > max_width

        result << chars[i]
        width += ch_w
        i += 1
      end

      # Close any open SGR sequences to prevent escape code leaking
      result << "\e[0m" if has_open_sgr

      result
    end

    def apply_border_sides(sides)
      values = sides.empty? ? [true, true, true, true] : expand_shorthand(sides)
      set_prop!(:border_top, values[0])
      set_prop!(:border_right, values[1])
      set_prop!(:border_bottom, values[2])
      set_prop!(:border_left, values[3])
    end

    def apply_border_colors(colors, type)
      suffix = type == :fg ? "_fg" : "_bg"
      parsed = colors.map { |c| Color.parse(c) }
      top, right, bottom, left = expand_shorthand(parsed)
      set_prop!(:"border_top#{suffix}", top)
      set_prop!(:"border_right#{suffix}", right)
      set_prop!(:"border_bottom#{suffix}", bottom)
      set_prop!(:"border_left#{suffix}", left)
    end
  end
end
