# frozen_string_literal: true

require_relative "chamomile/version"
require_relative "chamomile/messages"
require_relative "chamomile/model"
require_relative "chamomile/commands"

# Styling (formerly Flourish)
require_relative "chamomile/styling/ansi"
require_relative "chamomile/styling/color"
require_relative "chamomile/styling/color_profile"
require_relative "chamomile/styling/wrap"
require_relative "chamomile/styling/border"
require_relative "chamomile/styling/align"
require_relative "chamomile/styling/join"
require_relative "chamomile/styling/place"
require_relative "chamomile/styling/style"

# Components (formerly Petals)
require_relative "chamomile/components/key_binding"
require_relative "chamomile/components/spinner/types"
require_relative "chamomile/components/spinner"
require_relative "chamomile/components/text_input/key_map"
require_relative "chamomile/components/text_input"
require_relative "chamomile/components/stopwatch"
require_relative "chamomile/components/timer"
require_relative "chamomile/components/paginator/key_map"
require_relative "chamomile/components/paginator"
require_relative "chamomile/components/cursor"
require_relative "chamomile/components/help"
require_relative "chamomile/components/progress"
require_relative "chamomile/components/viewport/key_map"
require_relative "chamomile/components/viewport"
require_relative "chamomile/components/file_picker/key_map"
require_relative "chamomile/components/file_picker"
require_relative "chamomile/components/table/key_map"
require_relative "chamomile/components/table"
require_relative "chamomile/components/text_area/key_map"
require_relative "chamomile/components/text_area"
require_relative "chamomile/components/list/key_map"
require_relative "chamomile/components/list"
require_relative "chamomile/components/render_cache"
require_relative "chamomile/components/log_view"
require_relative "chamomile/components/command_palette"

# Layout DSL (depends on styling + components)
require_relative "chamomile/layout/base"
require_relative "chamomile/layout/raw"
require_relative "chamomile/layout/text"
require_relative "chamomile/layout/status_bar"
require_relative "chamomile/layout/panel"
require_relative "chamomile/layout/list"
require_relative "chamomile/layout/table"
require_relative "chamomile/layout/spinner"
require_relative "chamomile/layout/vertical"
require_relative "chamomile/layout/horizontal"
require_relative "chamomile/view_dsl"
require_relative "chamomile/application"
require_relative "chamomile/configuration"
require_relative "chamomile/options"
require_relative "chamomile/escape_parser"
require_relative "chamomile/key_map"
require_relative "chamomile/renderer"
require_relative "chamomile/input_reader"
require_relative "chamomile/program"
require_relative "chamomile/keymap"
require_relative "chamomile/router"
require_relative "chamomile/frame"
require_relative "chamomile/testing"
require_relative "chamomile/logging"

# Event-driven Ruby TUI framework.
module Chamomile
  # Position constants
  TOP = 0.0
  LEFT = 0.0
  CENTER = 0.5
  BOTTOM = 1.0
  RIGHT = 1.0

  # Symbol-to-float position map
  POSITION_MAP = {
    top: 0.0,
    left: 0.0,
    center: 0.5,
    bottom: 1.0,
    right: 1.0,
  }.freeze

  class << self
    def run(model, **opts, &block)
      if block
        config = Configuration.new
        block.call(config)
        opts = config.to_h.merge(opts)
      end
      Program.new(model, **opts).run
    end

    def width(str)
      ANSI.printable_width(str)
    end

    def height(str)
      ANSI.height(str)
    end

    def size(str)
      ANSI.size(str)
    end

    # New primary API — accepts array or block, keyword align
    def horizontal(strs = nil, align: :top, &block)
      strs = block.call if block && strs.nil?
      strs = Array(strs)
      Join.horizontal(resolve_position(align), *strs)
    end

    # New primary API — accepts array or block, keyword align
    def vertical(strs = nil, align: :left, &block)
      strs = block.call if block && strs.nil?
      strs = Array(strs)
      Join.vertical(resolve_position(align), *strs)
    end

    # New primary API — content first, keyword args
    # Also supports old positional form for backward compat
    def place(first, second = nil, third = nil, fourth = nil, fifth = nil,
              width: nil, height: nil, align: :left, valign: :top, content: nil)
      if fifth
        # Old 5-arg form: place(width, height, h_pos, v_pos, str)
        Place.place(first, second, resolve_position(third), resolve_position(fourth), fifth.to_s)
      else
        # New keyword form: place(content, width:, height:, align:, valign:)
        content = (content || first).to_s
        Place.place(width || 80, height || 24,
                    resolve_position(align), resolve_position(valign), content)
      end
    end

    # Old API — kept for backward compat
    def join_horizontal(position, *strs)
      Join.horizontal(resolve_position(position), *strs)
    end

    # Old API — kept for backward compat
    def join_vertical(position, *strs)
      Join.vertical(resolve_position(position), *strs)
    end

    def place_horizontal(width, pos, str)
      Place.place_horizontal(width, resolve_position(pos), str)
    end

    def place_vertical(height, pos, str)
      Place.place_vertical(height, resolve_position(pos), str)
    end

    # Convert symbol positions to float values.
    # Accepts symbols (:top, :left, :center, :bottom, :right) or floats.
    def resolve_position(val)
      case val
      when Symbol
        POSITION_MAP.fetch(val) { raise ArgumentError, "Unknown position: #{val.inspect}" }
      when Numeric
        val.to_f
      else
        raise ArgumentError, "Expected a Symbol or Numeric position, got #{val.inspect}"
      end
    end
  end
end
